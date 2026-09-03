# GEMB high-level framework:
# firm uses CostMinimizationKKTConditions;
# consumer uses MarginalUtilityConsumerConditions.
using GeneralEquilibriumModeling

alpha = 2.0
omega = 100.0
beta = [0.5, 0.5]

production_function =
    x -> alpha * sqrt(x[1] * x[2])

marginal_product_function =
    x -> [
        0.5 * alpha * sqrt(x[2] / x[1]),
        0.5 * alpha * sqrt(x[1] / x[2]),
    ]

model = GEMB.GEMBModel(
    [:product, :labor];
    numeraire=:product,
)

GEMB.add_agent!(
    model,
    GEMB.ProductionFunctionSpec(
        production_function,
        marginal_product_function;
        behavior=:cost_min,
    );
    outputs=:product,
    demands=[:product, :labor],
    activity_start=100.0,
    demand_start=[100.0, 100.0],
    name=:firm,
)

GEMB.add_agent!(
    model,
    GEMB.CESMarginalUtilitySpec(beta; es=1.0);
    demands=[:product, :labor],
    endowments=:labor,
    endowment_quantities=omega,
    demand_start=[100.0, 100.0],
    demand_lower_bounds=[1.0e-10, 1.0e-10],
    multiplier_start=0.01,
    name=:consumer,
)

result = GEMB.solve(
    model;
    p0=[1.0, 2.0],
    residual_tol=1.0e-8,
    silent=true,
)

stats = GEMB.equilibrium_statistics(model, result)

output = stats.activity_levels[1]

firm_variables = result.agent_variable_values[1]
firm_inputs = firm_variables[2:3]
production_multiplier = firm_variables[4]

consumer_variables = result.agent_variable_values[2]
consumption = consumer_variables[1:2]
budget_multiplier = consumer_variables[3]

utility = sqrt(prod(consumption))

GEMB.print_equilibrium_statistics(model, result)
println("Firm inputs = ", firm_inputs)
println("Production multiplier = ", production_multiplier)
println("Consumption = ", consumption)
println("Budget multiplier = ", budget_multiplier)
println("Utility = ", utility)