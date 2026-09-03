using GeneralEquilibriumModeling.GEM
using GeneralEquilibriumModeling.GEMB

k = 12 / 37

model = GEMBModel(
    [:commodity1, :commodity2];
    numeraire=:commodity2,
)

add_agent!(
    model,
    CESSpec([1.0, k^3]; es=1 / 3);
    demands=[:commodity1, :commodity2],
    endowments=:commodity1,
    endowment_quantities=1.0,
    name=:consumer1,
)

add_agent!(
    model,
    CESSpec([k^3, 1.0]; es=1 / 3);
    demands=[:commodity1, :commodity2],
    endowments=:commodity2,
    endowment_quantities=1.0,
    name=:consumer2,
)

for p0 in (
    [0.30, 1.0],
    [0.80, 1.0],
    [1.20, 1.0],
    [3.00, 1.0],
)
    result = solve(model; p0=p0, residual_tol=1e-10, silent=true)
    println("p0 = ", p0, "  =>  p* = ", result.prices)
end