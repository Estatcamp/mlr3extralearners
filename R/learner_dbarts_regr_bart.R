#' @title Regression BART (Bayesian Additive Regression Trees) Learner
#' @author ck37
#' @name mlr_learners_regr.bart
#'
#' @template class_learner
#' @templateVar id regr.bart
#' @templateVar caller bart
#'
#' @section Custom mlr3 defaults:
#' * Parameter: keeptrees
#' * Original: FALSE
#' * New: TRUE
#' * Reason: Required for prediction
#'
#' @template seealso_learner
#' @template example
#' @export
LearnerRegrBart <- R6Class("LearnerRegrBart",
  inherit = LearnerRegr,

  public = list(

    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      ps <- ParamSet$new(
        params = list(
          ParamInt$new(id = "ntree", default = 200L, lower = 1L, tags = "train"),
          ParamUty$new(id = "sigest", default = NULL, tags = "train"),
          ParamInt$new(id = "sigdf", default = 3L, lower = 1L, tags = "train"),
          ParamDbl$new(id = "sigquant", default = 0.90, lower = 0, upper = 1, tags = "train"),
          ParamDbl$new(id = "k", default = 2.0, lower = 0, tags = "train"),
          ParamDbl$new(id = "power", default = 2.0, lower = 0, tags = "train"),
          ParamDbl$new(id = "base", default = 0.95, lower = 0, tags = "train"),
          ParamInt$new(id = "ndpost", default = 1000L, lower = 1L, tags = "train"),
          ParamInt$new(id = "nskip", default = 100L, lower = 0L, tags = "train"),
          ParamInt$new(id = "printevery", default = 100L, lower = 0L, tags = "train"),
          ParamInt$new(id = "keepevery", default = 1L, lower = 1L, tags = "train"),
          ParamLgl$new(id = "keeptrainfits", default = TRUE, tags = "train"),
          ParamLgl$new(id = "usequants", default = FALSE, tags = "train"),
          ParamInt$new(id = "numcut", default = 100L, lower = 1L, tags = "train"),
          ParamInt$new(id = "printcutoffs", default = 0, tags = "train"),
          ParamLgl$new(id = "verbose", default = TRUE, tags = "train"),
          ParamLgl$new(id = "keeptrees", default = FALSE, tags = "train"),
          ParamLgl$new(id = "keepcall", default = TRUE, tags = "train"),
          ParamLgl$new(id = "sampleronly", default = FALSE, tags = "train"),
          ParamLgl$new(id = "offset.test", default = FALSE, tags = "predict")
        )
      )

      ps$values <- list(keeptrees = TRUE)

      super$initialize(
        id = "regr.bart",
        packages = "dbarts",
        feature_types = c("integer", "numeric", "factor", "ordered"),
        # TODO: add "se" to the list of predict types.
        predict_types = c("response"),
        param_set = ps,
        properties = c("weights"),
        man = "mlr3extralearners::mlr_learners_regr.bart"
      )
    }
  ),

  private = list(
    .train = function(task) {

      pars <- self$param_set$get_values(tags = "train")

      # Extact just the features from the task data.
      data <- task$data(cols = task$feature_names)

      # Convert from data.table to normal data.frame, just to be safe.
      # Dbarts expects x.train to be a dataframe.
      data.table::setDF(data)

      # This will also extract a data.table
      outcome <- task$data(cols = task$target_names)
      data.table::setDF(outcome)
      # Outcome will now be a factor vector.
      outcome <- outcome[[1]]

      if ("weights" %in% task$properties) {
        pars$weights <- task$weights$weight
      }

      # Use the mlr3misc::invoke function (it's similar to do.call())
      # y.train should either be a binary factor or have values {0, 1}
      mlr3misc::invoke(dbarts::bart,
        x.train = data, y.train = outcome,
        .args = pars
      )
    },

    .predict = function(task) {

      pars <- self$param_set$get_values(tags = "predict") # get parameters with tag "predict"

      newdata <- task$data(cols = task$feature_names) # get newdata

      # Other possible vars: offset.test, combineChains, ...
      data.table::setDF(newdata)

      # This will return a matrix of predictions, where each column is an observation
      # and each row is a sample from the posterior.
      p <- invoke(predict, self$model, newdata = newdata, .args = pars)

      # Transform predictions.
      # TODO: confirm that this is the correct element name.
      pred <- colMeans(p)

      mlr3::PredictionRegr$new(task = task, response = pred)
    }
  )
)

.extralrns_dict$add("regr.bart", LearnerRegrBart)
