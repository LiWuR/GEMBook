using GeneralEquilibriumModeling.GEMB

beta = 0.5
theta = exp(1.0)
xi = 0.25

positive_claim = false # Set to true for the alternative numerical example.

omega = positive_claim ? 1.5 : 3.0
alpha = positive_claim ? exp(-0.5) : exp(-2.0)

model = GEMBModel(
    [
        CommoditySpec(
            :product;
            price_lower_bound=1e-3,
        ),
        :labor,
        CommoditySpec(
            :scale_claim;
            price_lower_bound=positive_claim ? 1e-3 : -Inf,
            price_upper_bound=positive_claim ? Inf : -1e-3,
        ),
    ];
    numeraire=:labor,
)

add_agent!(
    model,
    ConditionAgentSpec(
        (variables, observed) -> begin
            tau = variables[1]
            activity = observed[1]

            [
                (1.0 + tau) * log(activity / alpha) - 1.0,
            ]
        end,
    );
    variable_names=:claim_rate,
    variable_start=positive_claim ? 0.6 : -0.3,
    variable_lower_bounds=-0.99,
    observed_variables=[
        agent_variable_ref(:firm, :activity),
    ],
    name=:scaleClaimSetter,
)

add_agent!(
    model,
    ActivityDemandSpec(
        (activity, prices, observed) -> begin
            p_labor, p_claim = prices
            tau = observed[1]

            x = log(activity / alpha) / log(theta)

            [
                x,
                tau * p_labor * x / p_claim,
            ]
        end;
        producer_condition_function=
            (variables, prices, net_supply) -> [
                -sum(prices .* net_supply),
            ],
    );
    outputs=:product,
    demands=[:labor, :scale_claim],
    observed_variables=[
        agent_variable_ref(
            :scaleClaimSetter,
            :claim_rate,
        ),
    ],
    activity_start=positive_claim ? 0.9 : 0.8,
    activity_lower_bound=alpha * theta^xi,
    name=:firm,
)

add_agent!(
    model,
    CESSpec([beta, 1.0 - beta]);
    demands=[:product, :labor],
    endowments=[:labor, :scale_claim],
    endowment_quantities=[omega, 1.0],
    activity_start=0.8,
    name=:consumer,
)

result = solve(
    model;
    p0=positive_claim ?
        [1.3, 1.0, 0.8] :
        [1.3, 1.0, -0.7],
    silent=true,
)

claim_rate = result.agent_variable_values[1][1]
activity = result.agent_variable_values[2][1]

print_equilibrium_statistics(model, result)

println("\nScale claim rate: ", claim_rate)
println("Firm activity: ", activity)