using GeneralEquilibriumModeling.GEMB

beta = 0.5
omega = 3.0

increasing_returns = true # Set to false for the alternative numerical example.

alpha = increasing_returns ? 0.25 : 2.0
theta = increasing_returns ? 2.0 : 0.5
tau = 1.0 / theta - 1.0

model = GEMBModel(
    [
        CommoditySpec(
            :product;
            price_lower_bound=1e-3,
        ),
        :labor,
        CommoditySpec(
            :claim;
            price_lower_bound=increasing_returns ? -Inf : 1e-3,
            price_upper_bound=increasing_returns ? 1e-3 : Inf,
        ),
    ];
    numeraire=:labor,
)

add_agent!(
    model,
    PowerProductionSpec(
        alpha=alpha,
        theta=theta,
    );
    outputs=:product,
    demands=:labor,
    claim=:claim,
    claim_rate=tau,
    activity_start=increasing_returns ? 0.8 : 1.5,
    activity_lower_bound=1.0e-6,
    name=:firm,
)

add_agent!(
    model,
    CESSpec([beta, 1.0 - beta]);
    demands=[:product, :labor],
    endowments=[:labor, :claim],
    endowment_quantities=[omega, 1.0],
    activity_start=1.5,
    name=:consumer,
)

result = solve(
    model;
    p0=increasing_returns ?
        [1.4, 1.0, -0.8] :
        [1.4, 1.0, 0.7],
    silent=true,
)

print_equilibrium_statistics(model, result)
print(result.solved)