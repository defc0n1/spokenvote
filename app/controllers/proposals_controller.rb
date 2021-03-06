class ProposalsController < ApplicationController
  include ApplicationHelper
  before_action :authenticate_user!, :except => [:show, :index, :related_vote_in_tree, :related_proposals]

  # GET /proposals.json
  def index
    if hub_id_google?(params[:hub])
      @proposals = []
      return render 'index'
    end

    @hub = Hub.find_by(id: params[:hub])
    @user = User.find_by(id: params[:user])

    proposals = Proposal.by_hub(@hub).by_user(@user).includes(:hub)

    unless params[:filter] == 'my'
      proposals = proposals.where(id: Proposal.top_voted_proposal_in_tree.map(&:id))
    end

    @proposals = filter_proposals(proposals, params[:filter].presence)

    if provided_user_id.present?
      user = User.find(provided_user_id)

      user_voted_proposal_root_ids = user.voted_proposals.map(&:root_id)
      @proposals = @proposals.reject { |proposal| !user_voted_proposal_root_ids.include? proposal.root_id }
    end

    @proposals = @proposals.sort { |a, b| b.votes_in_tree <=> a.votes_in_tree }
  end

  # GET /proposals/1.json
  def show
    eager_load = [:votes => { :user => :authentications }]
    @proposal = Proposal.includes(eager_load).where(id: params[:id]).first
  end

  # GET /proposals/new.json
  def new
    @proposal = Proposal.new
    @parent_proposal = Proposal.find(params[:parent_id]) if params[:parent_id]
    @vote = @proposal.votes.build
    respond_to do |format|
      format.json { render json: @proposal }
    end
  end

  # GET /proposals/1/edit.json
  def edit
    @proposal = Proposal.find(params[:id])
    render action: 'show'
  end

  # Get /proposals/:id/is_editable.json
  def is_editable
    proposal = Proposal.find(params[:id])
    render json: { editable: proposal.editable?(current_user) }
  end

  # POST /proposals.json
  def create
    attributes_from_params = params[:proposal][:votes_attributes]
    votes_attributes = (attributes_from_params || {}).merge(user_id: current_user.id, ip_address: request.remote_ip)
    @proposal = current_user.proposals.create(proposal_params)

    if @proposal.new_record?
      render json: @proposal.errors, status: :unprocessable_entity
    else
      Vote.move_user_vote_to_proposal(@proposal, current_user, votes_attributes)
      @proposal.reload  # needed to refresh the votes_count from db to this added proposal
      render 'show', status: :created
    end
  end

  # PUT /proposals/1.json
  def update
    @proposal = Proposal.find(params[:id])
    respond_to do |format|
      if @proposal.update_attributes(params[:proposal])
        format.json { render json: @proposal.to_json(methods: 'supporting_statement'), status: :ok }
      else
        format.json { render json: @proposal.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /proposals/1.json
  def destroy
    @proposal = Proposal.find(params[:id])
    @proposal.destroy

    redirect_to action: :index, status: :ok
  end

  # GET /proposals/:id/related_proposals.json
  def related_proposals
    params[:related_sort_by] ||= "Most Votes"
    proposal_id = (params[:proposal].presence || params[:id]).to_i
    @related_sort_by ||= params[:related_sort_by]
    @proposal = Proposal.find(proposal_id)
  end

  def related_vote_in_tree
    proposal = Proposal.find(params[:id])
    @vote = Vote.find_any_vote_in_tree_for_user(proposal, current_user)
  end

  private

  def find_hub
    if params[:hub]
      if params[:hub].is_a?(String) && params[:hub].starts_with?(GooglePlacesAutocompleteService.prefix)
        proposals = []
        render 'index'
      else
         @hub = Hub.find(params[:hub])
      end
    end
  end

  def filter_proposals(proposals, filter = 'active')
    case filter
    when 'active'
      proposals.sort { |a, b| b.votes_in_tree <=> a.votes_in_tree }
    when 'recent'
      proposals.by_recency
    when 'my'
      proposals.by_voting_user(current_user)
    else
      proposals
    end
  end

  def hub_id_google?(hub_id)
    hub_id.try(:starts_with?, GooglePlacesAutocompleteService.prefix) || false
  end

  def provided_user_id
    current_user.try(:id) || params[:user_id]
  end

  def proposal_params
    if parent_proposal
      params[:proposal].merge!(parent_id: parent_proposal.id, hub_id: parent_proposal.hub.id)
      params.require(:proposal).permit(:statement, :parent_id, :hub_id)
    else
      if existing_hub
        params.require(:proposal).permit(:statement, :hub_id)
      else
        params.require(:proposal).permit(
          :statement,
          hub_attributes: [:group_name, :location_id, :formatted_location, :description]
        )
      end
    end
  end

  def parent_proposal
    @parent ||= Proposal.find_by_id(params[:proposal][:parent_id])
  end

  def existing_hub
    if !hub_id_google?(params[:proposal][:hub_id]) # no need to hit db if hub doesn't exist in our DB yet
      @hub ||= Hub.find_by_id(params[:proposal][:hub_id])
    else
      nil
    end
  end

end
