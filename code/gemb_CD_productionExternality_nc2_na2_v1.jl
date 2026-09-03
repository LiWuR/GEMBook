# GEMB high-level framework: production externality.
using GeneralEquilibriumModeling.GEMB

omega = 12.0
kappa = 1.0 / 8.0

model = GEMBModel(
    [:product, :labor];
    numeraire=:labor,
)

add_agent!(
    model,
    CESSpec([1.0]);
    outputs=:product,
    demands=:labor,
    activity_start=4.0,
    name=:firm,
)

add_agent!(
    model,
    MarshallDemandConsumerSpec(
        (income, prices, observed) -> begin
            activity = observed[1]
            [
                (1.0 - kappa * activity) / (2.0 - kappa * activity) *
                    income / prices[1],
                income / ((2.0 - kappa * activity) * prices[2]),
            ]
        end,
    );
    demands=[:product, :labor],
    endowments=:labor,
    endowment_quantities=omega,
    observed_variables=[
        agent_variable_ref(AgentRef(:firm), :activity),
    ],
    name=:consumer,
)

result = solve(
    model;
    p0=[2.0, 1.0],
    silent=true,
)

print_equilibrium_statistics(model, result)