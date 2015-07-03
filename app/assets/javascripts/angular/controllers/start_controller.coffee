#StartController = [ '$scope', '$location', 'Focus', '$timeout', '$route', 'proposal', ( $scope, $location, Focus, $timeout, $route, proposal ) ->
StartController = [ '$rootScope', '$scope', '$location', 'Focus', '$timeout', '$route', ( $rootScope, $scope, $location, Focus, $timeout, $route ) ->
  $scope.alertService.clearAlerts()

  $scope.sessionSettings.actions.hubShow = false  unless $scope.sessionSettings.hub_attributes or $scope.sessionSettings.actions.newProposal.started
  $scope.sessionSettings.actions.newProposal.started = true
  $scope.sessionSettings.actions.hubSeekOnSearch = false
  $scope.sessionSettings.actions.hubPlaceholder = 'Who should see your proposal? ...'
  $rootScope.sessionSettings.actions.improveProposal.propStepText = 'You have 140 characters to state your proposal.'

  if $scope.sessionSettings.newProposal.statement? and $scope.sessionSettings.hub_attributes?
    $scope.sessionSettings.actions.focus = 'comment'
    Focus '#new_vote_comment'
  else
    Focus '#new_proposal_statement'

#  $scope.commentStep = ->
#    $scope.sessionSettings.actions.newProposal.comment = 'active'
#    Focus '#new_vote_comment'
#
#  $scope.hubStep = ->
#    $scope.sessionSettings.actions.newProposal.comment = 'complete'
#    $scope.sessionSettings.actions.focus = 'hub'
#    $scope.sessionSettings.actions.hubShow = true
#    if $scope.sessionSettings.hub_attributes
#      if $scope.newProposalForm.$valid
#        $scope.sessionSettings.actions.focus = 'publish'
#        Focus '#new_vote_comment'
#      else
#        $scope.alertService.setErrorMsg 'The proposal is not quite right, too short perhaps?', $scope, 'main'
#    else
#      $rootScope.$broadcast 'focusHubFilter'
#
#  $rootScope.finishProp = ->
#    console.log 'finishProp: '
#    $scope.sessionSettings.actions.newProposal.hub = 'complete'
#    $scope.sessionSettings.actions.focus = 'publish'
#    $timeout (-> Focus '#new_vote_comment'), 500

]

App.controller 'StartController', StartController
