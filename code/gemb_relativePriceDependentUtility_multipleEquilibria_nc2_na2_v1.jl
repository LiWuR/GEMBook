using GeneralEquilibriumModeling

const S1 = 1.0
const S2 = 3.0

model = GEMB.GEMBModel(
    [:commodity1, :commodity2];
    numeraire=:commodity2,
    numeraire_value=1.0,
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
        p1 * income / (p1^2 + p2^2),
        p2 * income / (p1^2 + p2^2),
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

result_low = GEMB.solve(
    model;
    p0=[0.3, 1.0],
    residual_tol=1.0e-10,
    silent=true,
)

result_high = GEMB.solve(
    model;
    p0=[3.0, 1.0],
    residual_tol=1.0e-10,
    silent=true,
)

result_boundary = GEMB.solve(
    model;
    p0=[0.0, 1.0],
    residual_tol=1.0e-10,
    silent=true,
)

p1_low_exact = (S2 - sqrt(S2^2 - 4S1^2)) / (2S1)
p1_high_exact = (S2 + sqrt(S2^2 - 4S1^2)) / (2S1)

println("Lower positive equilibrium prices: ", result_low.prices)
println("Higher positive equilibrium prices:", result_high.prices)
println("Boundary equilibrium prices:       ", result_boundary.prices)
println(
    "Boundary net supply:        ",
    result_boundary.total_net_supply,
)

nothing
