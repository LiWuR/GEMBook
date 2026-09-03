using GeneralEquilibriumModeling

alpha = 2.0
beta = 0.5
omega = 90.0
tau = 0.5

model = GEMB.GEMBModel(
    [:product, :labor, :tax_certificate];
    numeraire=:labor,
    numeraire_value=1.0,
)

firm_spec = GEMB.ActivityDemandSpec(
    function (output, prices)
        p_labor, p_tax = prices

        return [
            output / alpha,
            tau * output / p_tax,
        ]
    end,
)

GEMB.add_agent!(
    model,
    firm_spec;
    outputs=:product,
    demands=[:labor, :tax_certificate],
    activity_start=100.0,
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
    endowments=[:labor, :tax_certificate],
    endowment_quantities=[omega, 1.0],
    activity_start=100.0,
    name=:consumer,
)

result = GEMB.solve(
    model;
    p0=[1.0, 1.0, 30.0],
    residual_tol=1.0e-8,
    silent=true,
)

stats = GEMB.equilibrium_statistics(model, result)

output = stats.activity_levels[1]
utility = stats.activity_levels[2]

GEMB.print_equilibrium_statistics(model, result)
