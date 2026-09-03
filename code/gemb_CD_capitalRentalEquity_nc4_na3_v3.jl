using GeneralEquilibriumModeling

discount_factor = 0.97
return_rate = 1 / discount_factor - 1
delta = 0.06
beta_firm = 0.35
beta_consumer = 0.4

model = GEMB.GEMBModel(
    [
        :product,
        :labor,
        :capital_service,
        GEMB.CommoditySpec(:equity; price_lower_bound=1.0e-10),
    ];
    numeraire=:product,
    numeraire_value=1.0,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec([1 - beta_firm, beta_firm]);
    outputs=:product,
    demands=[:labor, :capital_service],
    activity_start=100.0,
    name=:production_firm,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec([beta_consumer, 1 - beta_consumer]);
    demands=[:product, :labor],
    endowments=[:labor, :equity],
    endowment_quantities=[1.0, 1.0],
    activity_start=100.0,
    name=:consumer,
)

GEMB.add_agent!(
    model,
    GEMB.CESSpec([1.0]);
    outputs=[:product, :capital_service],
    output_coefficients=[1 - delta, 1.0],
    demands=:product,
    claim_rate=return_rate,
    claim=GEMB.CommodityRef(:equity),
    activity_start=100.0,
    name=:capital_rental_firm,
)

result = GEMB.solve(
    model;
    p0=[1.0, 1.343115, 0.090928, 0.088654],
    residual_tol=1.0e-8,
    silent=true,
)

stats = GEMB.equilibrium_statistics(model, result)

flows = GEMB.demand_supply_matrices(model, result)

D = flows.demand
S = flows.supply
Sbar = flows.net_supply

GEMB.print_equilibrium_statistics(model, result)

println("\nDemand matrix D:")
display(hcat(D, flows.total_demand))

println("\nSupply matrix S:")
display(hcat(S, flows.total_supply))
