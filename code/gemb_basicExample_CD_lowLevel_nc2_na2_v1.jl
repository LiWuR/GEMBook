# GEMB low-level framework: build NetSupplyAgents from ActivityDemandSpec.
using GeneralEquilibriumModeling

alpha = 2.0
omega = 100.0
beta = [0.5, 0.5]

c = (product=1, labor=2)

firm = GEMB.build_agent(
    GEMB.ActivityDemandSpec(
        (y, p) -> GEMB.CES_input(beta, y, p; es=1.0, alpha=alpha),
    );
    output_indices=[c.product],
    output_coefficients=[1.0],
    demand_indices=[c.product, c.labor],
    activity_start=100.0,
    name=:firm,
)

consumer = GEMB.build_agent(
    GEMB.ActivityDemandSpec(
        (u, p) -> GEMB.CES_input(beta, u, p; es=1.0, alpha=1.0),
    );
    demand_indices=[c.product, c.labor],
    endowment_indices=[c.labor],
    endowment_quantities=[omega],
    activity_start=100.0,
    name=:consumer,
)

model = GEM.NetSupplyEquilibriumModel(
    GEM.AbstractNetSupplyAgent[firm, consumer],
    [:product, :labor];
    numeraire_index=c.product,
    numeraire_value=1.0,
    price_lower_bounds=[1.0e-10, 1.0e-10],
)

result = GEM.solve_equilibrium_model_mcp_jump(
    model;
    p0=[1.0, 2.0],
    residual_tol=1.0e-8,
    silent=true,
)

output = result.agent_variable_values[1][1]
utility = result.agent_variable_values[2][1]

println("Prices = ", result.prices)
println("Output = ", output)
println("Utility = ", utility)