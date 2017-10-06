library(metaflu)
library(ggplot2)
library(dplyr)
library(doMC)
library(tidyr)
library(purrr)
library(gridExtra)
library(abind)
library(doRNG)
library(grid)
set.seed(123)

registerDoMC(cores = 20)

# Copied from summarizing-functions in metaflu, which is definitely not the most elegant way to change a function

#' 2-Dimensional Parameter Variation
#'
#' Returns an array of the results of varying the 2 given parameters over the given ranges.
#' @export
#' @importFrom parallel detectCores
#' @param param_value the name of the parameter to vary
#' @param param_vector the range over which the parameter will vary
#' @param sims the number of simulations to run for each value of the parameter
#' @param farm_num the number of farms in the network
#' @param farm_size the typical farm size
#' @param parms the list of parameters
vary_params_2d <- function(param1_name, param1_values, param2_name, param2_values, sims = 1000, num_of_farms = 200, num_of_chickens = 50,
                           parms = list(
                             beta = 1.44456,   #contact rate for direct transmission
                             gamma = 0.167,  #recovery rate
                             mu = 0,         #base mortality rate
                             alpha = 0.4,      #disease mortality rate
                             phi = 0,  #infectiousness of environmental virions
                             eta = 0,     #degradation rate of environmental virions
                             nu =  0.00,    #uptake rate of environmental virion
                             sigma = 0,      #virion shedding rate
                             omega = 0.03,   #movement rate
                             rho = 0.85256,        #contact  nonlinearity 0=dens-dependent, 1=freq-dependent
                             lambda = 0,     #force of infection from external sources
                             tau_crit = 5,   #critical suveillance time
                             I_crit = 1,     #threshold for reporting
                             pi_report = 1, #reporting probability
                             pi_detect = 1, #detection probability
                             cull_time = 1,   #time to detect
                             network_type = "smallworld",
                             network_parms = list(dim = 1, size = num_of_farms, nei = 2.33, p = 0.0596, multiple = FALSE, loops = FALSE),
                             stochastic_network = TRUE
                           )){
  param_combos <- expand.grid(param1_values, param2_values)
  results_list <- purrr::map2(param_combos[,1],param_combos[,2],function(a,b){
    parms[[param1_name]] <- a
    parms[[param2_name]] <- b
    g_list <- mclapply(seq_len(sims), function(y){
      patches <- basic_patches(num_of_chickens, num_of_farms)
      i_patches <- seed_initial_infection(patches)
      return(mf_sim(init = i_patches, parameters = parms, times=1:365, n_sims = 1))
    }, mc.cores = detectCores()/2)
    bound_array <- do.call("abind", g_list)
    attributes(bound_array)[[param1_name]] <- a
    attributes(bound_array)[[param2_name]] <- b
    return(bound_array)
  })
  return(results_list)
}

# Setup (2D)
# For the presentation, farm size varied from (50, 200, 100) and omega from (0.01, 0.03, 0.05)
num_of_farms = 50 #200 is default
threshold_1 = 1
varied_param_1 = "cull_time"

threshold_2 = 0.01
varied_param_2 = "omega"

results_list <- vary_params_2d(param1_name = varied_param_1, param1_values = threshold_1, param2_name = varied_param_2,
                               param2_values = threshold_2)

saveRDS(results_list, "test.rds")