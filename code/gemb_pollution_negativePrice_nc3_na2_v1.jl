# GEMB high-level framework: pollution with a negative equilibrium price.
using GeneralEquilibriumModeling

a = 1.0
c = 1.0
beta = 0.5
delta = 1.0 / 8.0
omega = 6.0

model = GEMB.GEMBModel(
    [
        :product,
        :labor,
        GEMB.CommoditySpec(
            :pollution;
            price_lower_bound=-Inf,
            price_upper_bound=Inf,
        ),
    ];
    numeraire=:labor,
    numeraire_value=1.0,
)

firm_spec = GEMB.ActivityDemandSpec(
    (z, prices) -> [a * z],
)

GEMB.add_agent!(
    model,
    firm_spec;
    outputs=[:product, :pollution],
    output_coefficients=[1.0, c],
    demands=:labor,
    activity_start=100.0,
    name=:firm,
)

consumer_spec = GEMB.MarginalUtilityConsumerSpec(
    demand -> begin
        x, l, q = demand
        [
            beta / x,
            (1.0 - beta) / l,
            -delta,
        ]
    end,
)

GEMB.add_agent!(
    model,
    consumer_spec;
    demands=[:product, :labor, :pollution],
    endowments=:labor,
    endowment_quantities=omega,
    demand_start=[100.0, 100.0, 100.0],
    demand_lower_bounds=[1.0e-10, 1.0e-10, 0.0],
    multiplier_start=1.0,
    multiplier_lower_bound=0.0,
    name=:consumer,
)

result = GEMB.solve(
    model;
    p0=[1.0, 1.0, -0.5],
    residual_tol=1.0e-10,
    silent=true,
)

GEMB.print_equilibrium_statistics(
    model,
    result;
    display_tol=1.0e-10,
    sigdigits=8,
)