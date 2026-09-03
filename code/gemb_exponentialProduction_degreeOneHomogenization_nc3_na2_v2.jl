using GeneralEquilibriumModeling

decreasing_returns = false  # Set to true for the alternative numerical example.

beta = 0.5
omega = 3.0

theta = decreasing_returns ? exp(0.5) : exp(1.0)
alpha = decreasing_returns ? 2.0 / theta : 1.0 / theta^2

output_start = 1.5
labor_start = 1.5
scale_claim_start = 1.2

p0 = decreasing_returns ?
    [1.0, 0.8, 0.5] :
    [1.0, 0.8, -0.5]

# Degree-one homogenization:
# g(x, c) = c * f(x / c) = alpha * c * theta^(x / c)
production_function = inputs -> begin
    x, c = inputs
    alpha * c * theta^(x / c)
end

# Scaled marginal product function:
# the common strictly positive factor alpha * theta^(x / c) is omitted.
marginal_product_function = inputs -> begin
    x, c = inputs

    [
        log(theta),
        1.0 - (x / c) * log(theta),
    ]
end

model = GEMB.GEMBModel(
    [
        :product,
        GEMB.CommoditySpec(
            :labor;
            price_lower_bound=1.0e-10,
        ),
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
    activity_start=output_start,
    demand_start=[labor_start, scale_claim_start],
    demand_lower_bounds=[1.0e-10, 1.0e-10],
    production_multiplier_start=1.0,
    name=:firm,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec(
        [beta, 1.0 - beta];
        es=1.0,
        alpha=1.0,
    );
    demands=[:product, :labor],
    endowments=[:labor, :scale_claim],
    endowment_quantities=[omega, 1.0],
    name=:consumer,
)

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

theoretical_claim_rate =
    1.0 / (labor_input * log(theta)) - 1.0

println("\nScale-claim check:")
println("production elasticity = ", labor_input * log(theta))
println("theoretical claim rate = ", theoretical_claim_rate)
println("implied claim rate = ", implied_claim_rate)