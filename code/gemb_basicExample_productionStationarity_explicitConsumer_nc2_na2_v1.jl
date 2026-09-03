# production stationarity conditions and explicit consumer conditions.
using GeneralEquilibriumModeling

alpha = 2.0
omega = 100.0
beta = [0.5, 0.5]

production_function = x -> alpha * sqrt(x[1] * x[2])

marginal_product_function = x -> [
    0.5 * alpha * sqrt(x[2] / x[1]),
    0.5 * alpha * sqrt(x[1] / x[2]),
]

model = GEMB.GEMBModel(
    [:product, :labor];
    numeraire=:product,
    numeraire_value=1.0,
)

GEMB.add_agent!(
    model,
    GEMB.ProductionFunctionSpec(
        production_function,
        marginal_product_function;
        behavior=:stationary,
    );
    outputs=:product,
    demands=[:product, :labor],
    activity_start=100.0,
    demand_start=[100.0, 100.0],
    demand_lower_bounds=[1.0e-10, 1.0e-10],
    production_multiplier_start=1.0,
    name=:firm,
)

consumer_net_supply = function (v, p, observed_values=Any[])
    [-v[1], omega - v[2]]
end

consumer_conditions = function (v, p, net_supply)
    x = v[1:2]
    mu = v[3]

    return [
        mu * p[1] - beta[1] / x[1],
        mu * p[2] - beta[2] / x[2],
        sum(p .* net_supply),
    ]
end

GEMB.add_net_supply_agent!(
    model,
    consumer_net_supply;
    commodities=[:product, :labor],
    variable_names=[:demand_product, :demand_labor, :budget_multiplier],
    variable_lower_bounds=[1.0e-10, 1.0e-10, 0.0],
    variable_upper_bounds=[Inf, Inf, Inf],
    variable_start=[100.0, 100.0, 0.01],
    condition_rule=GEM.ExplicitAgentConditions(consumer_conditions),
    name=:consumer,
)

result = GEMB.solve(
    model;
    p0=[1.0, 2.0],
    residual_tol=1.0e-8,
    silent=true,
)

output = result.agent_variable_values[1][1]
consumption = result.agent_variable_values[2][1:2]
utility = sqrt(prod(consumption))

println("Prices = ", result.prices)
println("Output = ", output, ", utility = ", utility)

@assert result.solved
@assert isapprox(result.prices, [1.0, 1.0]; atol=1.0e-7)
@assert isapprox(output, 100.0; atol=1.0e-6)
@assert isapprox(utility, 50.0; atol=1.0e-7)
@assert maximum(abs, result.total_net_supply) <= 1.0e-7