# GEMB high-level framework: total revenue-expenditure balance conditions.
using GeneralEquilibriumModeling

alpha = 2.0
omega = 100.0
beta = [0.5, 0.5]

model = GEMB.GEMBModel(
    [:product, :labor];
    numeraire=:product,
    numeraire_value=1.0,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec(beta; es=1.0, alpha=alpha);
    outputs=:product,
    demands=[:product, :labor],
    activity_start=0.0,
    condition_rule=GEM.TotalRevenueExpenditureBalanceConditions(),
    name=:firm1,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec(beta; es=1.0, alpha=1.0);
    demands=[:product, :labor],
    endowments=:labor,
    endowment_quantities=omega,
    name=:consumer,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec(beta; es=1.0, alpha=1.0);
    outputs=:product,
    demands=[:product, :labor],
    activity_start=1.0,
    condition_rule=GEM.TotalRevenueExpenditureBalanceConditions(),
    name=:firm2,
)

result = GEMB.solve(
    model;
    p0=[1.0, 0.27],
    residual_tol=1.0e-8,
    silent=true,
)

stats = GEMB.equilibrium_statistics(model, result)

output1 = stats.activity_levels[1]
utility = stats.activity_levels[2]
output2 = stats.activity_levels[3]

GEMB.print_equilibrium_statistics(model, result)

println("Output1 = ", output1,
        ", output2 = ", output2,
        ", utility = ", utility)
