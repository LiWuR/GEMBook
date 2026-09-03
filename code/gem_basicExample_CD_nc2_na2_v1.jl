# GEM framework: define net supplies and condition rules directly.
using GeneralEquilibriumModeling.GEM

alpha = 2.0
omega = 100.0

c = (product=1, labor=2)

firm = GEM.NetSupplyAgent(
    [c.product, c.labor],
    (v, p) -> begin
        y = v[1]
        p_product, p_labor = p
        r = sqrt(p_labor / p_product)
        x = (y / alpha) .* [r, 1 / r]
        [y - x[1], -x[2]]
    end;
    variable_names=[:output],
    variable_start=[100.0],
    condition_rule=GEM.UnitRevenueExpenditureBalanceConditions(),
    name=:firm,
)

consumer = GEM.NetSupplyAgent(
    [c.product, c.labor],
    (v, p) -> begin
        u = v[1]
        p_product, p_labor = p
        r = sqrt(p_labor / p_product)
        x = u .* [r, 1 / r]
        [-x[1], omega - x[2]]
    end;
    variable_names=[:utility],
    variable_start=[100.0],
    condition_rule=GEM.TotalRevenueExpenditureBalanceConditions(),
    name=:consumer,
)

model = GEM.NetSupplyEquilibriumModel(
    [firm, consumer],
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
println("Output = ", output, ", utility = ", utility)