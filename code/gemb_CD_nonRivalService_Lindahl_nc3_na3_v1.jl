using GeneralEquilibriumModeling

beta1 = 1 / 4
beta2 = 2 / 3
omega1 = 120.0
omega2 = 90.0

model = GEMB.GEMBModel(
    [:service1, :service2, :labor];
    numeraire=:labor,
    numeraire_value=1.0,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec([1.0]);
    outputs=[:service1, :service2],
    demands=:labor,
    activity_start=100.0,
    name=:firm,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec([beta1, 1 - beta1]);
    demands=[:service1, :labor],
    endowments=:labor,
    endowment_quantities=omega1,
    activity_start=100.0,
    name=:consumer1,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec([beta2, 1 - beta2]);
    demands=[:service2, :labor],
    endowments=:labor,
    endowment_quantities=omega2,
    activity_start=100.0,
    name=:consumer2,
)

result = GEMB.solve(
    model;
    p0=[0.5, 0.5, 1.0],
    residual_tol=1.0e-8,
    silent=true,
)

GEMB.print_equilibrium_statistics(model, result)
