using GeneralEquilibriumModeling

beta = [0.5, 0.5]

model = GEMB.GEMBModel(
    [:commodity1, :commodity2];
    numeraire=:commodity2,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec(
        beta;
        es=1.0,
        alpha=1.0,
    );
    demands=[:commodity1, :commodity2],
    endowments=:commodity1,
    endowment_quantities=100.0,
    activity_start=100.0,
    name=:consumer1,
)

GEMB.add_agent!(
    model,
    GEMB.DCESSpec(
        beta;
        es=1.0,
        alpha=1.0,
        xi=[0.0, 20.0],
    );
    demands=[:commodity1, :commodity2],
    endowments=:commodity2,
    endowment_quantities=100.0,
    activity_start=100.0,
    name=:consumer2,
)

result = GEMB.solve(
    model;
    p0=[1.0, 1.0],
    silent=true,
)

GEMB.print_equilibrium_statistics(model, result)

flows = GEMB.demand_supply_matrices(model, result)

D = flows.demand
S = flows.supply

println("\nDemand matrix D:")
display(D)

println("\nSupply matrix S:")
display(S)