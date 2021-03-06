install_learners("regr.earth")

test_that("autotest", {
  learner = lrn("regr.earth")
  expect_learner(learner)
  result = run_autotest(learner)
  expect_true(result, info = result$error)
})
