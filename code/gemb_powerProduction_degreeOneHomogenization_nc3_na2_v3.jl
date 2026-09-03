using GeneralEquilibriumModeling

decreasing_returns = false  # Set to true for the alternative numerical example.

beta = 0.5
omega = 3.0

alpha = decreasing_returns ? 2.0 : 0.25
theta = decreasing_returns ? 0.5 : 2.0
tau = 1.0 / theta - 1.0

production_function = inputs -> begin
    x, c = inputs
    alpha * x^theta * c^(1.0 - theta)
end

marginal_product_function = inputs -> begin
    x, c = inputs

    [
        alpha * theta * x^(theta - 1.0) * c^(1.0 - theta),
        alpha * (1.0 - theta) * x^theta * c^(-theta),
    ]
end

model = GEMB.GEMBModel(
    [
        :product,
        GEMB.CommoditySpec(:labor; price_lower_bound=1.0e-10),
        GEMB.CommoditySpec(
            :scale_claim;
            price_lower_bound=-Inf,
            price_upper_bound=Inf,
        ),
    ];
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
    demands=[:labor, :scale_claim],
    activity_start=decreasing_returns ? 2.0 : 1.0,
    demand_start=[decreasing_returns ? 1.0 : 2.0, 1.0],
    demand_lower_bounds=[1.0e-10, 1.0e-10],
    production_multiplier_start=1.0,
    name=:firm,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec([beta, 1.0 - beta]; es=1.0, alpha=1.0);
    demands=[:product, :labor],
    endowments=[:labor, :scale_claim],
    endowment_quantities=[omega, 1.0],
    name=:consumer,
)

p0 = decreasing_returns ?
    [1.0, 1.0, 1.0] :
    [1.0, 1.0, -1.0]

result = GEMB.solve(
    model;
    p0=p0,
    residual_tol=1.0e-8,
    silent=true,
)

GEMB.print_equilibrium_statistics(model, result)

_, labor_input, scale_claim_input, _ =
    result.agent_variable_values[1]

implied_claim_rate =
    result.prices[3] * scale_claim_input /
    (result.prices[2] * labor_input)

println("\nScale-claim rate:")
println("theoretical = ", tau)
println("implied = ", implied_claim_rate)