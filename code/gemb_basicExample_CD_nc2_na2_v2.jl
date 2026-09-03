# GEMB high-level framework: use commodity names and behavioral specifications.
using GeneralEquilibriumModeling.GEMB

alpha = 2.0
omega = 100.0
beta = [0.5, 0.5]

model = GEMBModel(
    [:product, :labor];
    numeraire=:product,
)

add_agent!(
    model,
    CESSpec(beta; es=1.0, alpha=alpha);
    outputs=:product,
    demands=[:product, :labor],
    activity_start=100.0,
    name=:firm,
)

add_agent!(
    model,
    CESSpec(beta; es=1.0, alpha=1.0);
    demands=[:product, :labor],
    endowments=:labor,
    endowment_quantities=omega,
    activity_start=100.0,
    name=:consumer,
)

result = solve(
    model;
    p0=[1.0, 2.0],
    residual_tol=1.0e-8,
    silent=true,
)

stats = equilibrium_statistics(model, result)

output = stats.activity_levels[1]
utility = stats.activity_levels[2]

flows = demand_supply_matrices(model, result)

D = flows.demand
S = flows.supply
Sbar = flows.net_supply

DV = flows.demand_value
SV = flows.supply_value

@assert S - D ≈ Sbar
@assert flows.total_demand ≈ flows.total_supply
@assert flows.agent_expenditure ≈ flows.agent_revenue

print_equilibrium_statistics(model, result)

println("\nDemand matrix D:")
display(hcat(D, flows.total_demand))

println("\nSupply matrix S:")
display(hcat(S, flows.total_supply))

println("\nDemand value matrix DV:")
display([
    hcat(DV, flows.total_demand_value)
    hcat(permutedims(flows.agent_expenditure), sum(flows.agent_expenditure))
])

println("\nSupply value matrix SV:")
display([
    hcat(SV, flows.total_supply_value)
    hcat(permutedims(flows.agent_revenue), sum(flows.agent_revenue))
])