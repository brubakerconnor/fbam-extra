# Simulation study ####
# Ensure the working directory is the fbam-sims directory
# perform many repetitions of the fbam optimization routine on independent
# realizations of a given model with given parameters
# arguments 7-10 are optional. if not specified, default parameter values will
# be used in running the genetic algorithm.
# [1] model_name        string    e.g., "model1", "model2a"
# [2] nrep              integer   number of replicate time series (per subpopulation)
# [3] len               integer   length of the time series epochs
# [4] nsim              integer   number of simulation repetitions (e.g., 100)
# [5] ncores            integer   number of cores to use for parallelization
# [6] results_dir       string    where to save the simulation results (.rds file)
args <- commandArgs(trailingOnly = T)
model_name <- args[1]
nrep <- as.integer(args[2])
len <- as.integer(args[3])
nsim <- as.integer(args[4])
ncores <- as.integer(args[5])
results_dir <- args[6]

# make sure results directory exists
if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

# set seed for reproducibility and load fbam library
set.seed(451)
library(fbam)
source("sim_models.R")

# print parameter settings to log
cat("STUDY PARAMETERS:\n",
    "nsim: ", nsim, "\n",
    "ncores: ", ncores, "\n",
    "model_name: ", model_name, "\n",
    "nrep: ", nrep, "\n",
    "len: ", len, "\n",
    "results_dir: ", results_dir, "\n")

# path to results data file



# run simulation nsim times and save results to disk at each iteration
SIM_START_TIME <- Sys.time()
output_data <- list()
nsuccess <- 0; nfail <- 0
while (nsuccess < nsim & nfail < nsim) {
  # attempt the simulation until the required number of successes are met
  # terminate once too many failures occur
  tryCatch({
    data_fname <- file.path(results_dir,
                            paste0(model_name, "_nrep=", nrep, "_len=", len,
                                   "_run=", nsuccess + 1, ".rds"))
    cat("Results saved to", data_fname, "\n")
    
    cat("\nReplicate starting at", format(Sys.time(), usetz = TRUE), "\n")
    cat("Number of successful runs:", nsuccess, "\n")
    cat("Number of failed runs:", nfail, "\n")
    cat("Generating data...\n")
    dat <- get(model_name)(nrep, len)
    
    cat("Running FBAM on generated data...\n")
    FBAM_START_TIME <- Sys.time()
    out <- fbam(dat$x, nbands = 2:6, nsubpop = 2:6, ncores = ncores)
    FBAM_RUNTIME <- as.numeric(Sys.time() - FBAM_START_TIME, units = "secs")
    cat("Completed in", FBAM_RUNTIME, " seconds.\n")
    
    cat("Saving results to disk...\n")
    out <- list(data = dat, fbam_out = out, time = FBAM_RUNTIME)
    save(out, file = data_fname)
    nsuccess <- nsuccess + 1
  }, error = function(e) {
    assign("nfail", nfail + 1, env=globalenv())
    cat('\n', str(e), '\n')
  })
}
cat("\n\nRUN COMPLETED", format(Sys.time(), usetz = TRUE), "\n")
cat("TOTAL RUNTIME", format(Sys.time() - SIM_START_TIME, usetz = TRUE), "\n\n")

