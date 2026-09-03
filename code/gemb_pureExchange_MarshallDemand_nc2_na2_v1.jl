using GeneralEquilibriumModeling

beta1 = 0.5
beta2 = 0.25
omega1 = 100.0
omega2 = 100.0

marshall_demand(beta) = (income, prices) -> [
    beta * income / prices[1],
    (1.0 - beta) * income / prices[2],
]

model = GEMB.GEMBModel(
    [
        GEMB.CommoditySpec(
            :commodity1;
            price_lower_bound=0.05,
        ),
        GEMB.CommoditySpec(
            :commodity2;
            price_lower_bound=0.05,
        ),
    ];
    numeraire=:commodity2,
)

GEMB.add_agent!(
    model,
    GEMB.MarshallDemandConsumerSpec(
        marshall_demand(beta1),
    );
    demands=[:commodity1, :commodity2],
    endowments=:commodity1,
    endowment_quantities=omega1,
    name=:consumer1,
)

GEMB.add_agent!(
    model,
    GEMB.MarshallDemandConsumerSpec(
        marshall_demand(beta2),
    );
    demands=[:commodity1, :commodity2],
    endowments=:commodity2,
    endowment_quantities=omega2,
    name=:consumer2,
)

result = GEMB.solve(
    model;
    p0=[1.0, 1.0],
    silent=true,
)

GEMB.print_equilibrium_statistics(model, result)