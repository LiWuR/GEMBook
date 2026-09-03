using GeneralEquilibriumModeling

const S1 = 4.0
const S2 = 4.0
const Q = 1.5

model = GEMB.GEMBModel(
    [:commodity1, :commodity2];
    numeraire=:commodity1,
    numeraire_value=Q,
)

consumer1_demand = (income, prices) -> [
    income / prices[1],
]

GEMB.add_agent!(
    model,
    GEMB.MarshallDemandConsumerSpec(consumer1_demand);
    demands=:commodity2,
    endowments=:commodity1,
    endowment_quantities=[S1],
    name=:consumer1,
)

consumer2_demand = function (income, prices)
    p1, p2 = prices

    return [
        income / (2p1) + p1,
        income / (2p2) - p1^2 / p2,
    ]
end

GEMB.add_agent!(
    model,
    GEMB.MarshallDemandConsumerSpec(consumer2_demand);
    demands=[:commodity1, :commodity2],
    endowments=:commodity2,
    endowment_quantities=[S2],
    name=:consumer2,
)

result = GEMB.solve(
    model;
    p0=[Q, 1.0],
    residual_tol=1.0e-10,
    silent=true,
)

println("Equilibrium prices: ", result.prices)