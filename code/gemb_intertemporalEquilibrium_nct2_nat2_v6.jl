# GEMB high-level framework: intertemporal equilibrium.
using GeneralEquilibriumModeling

np = 5

initial_product_endowment = 150.0
labor_endowment = 100.0
positive_price_floor = 1.0e-10

product = GEMB.CommoditySpec(
    :product;
    axes=(period=1:np,),
    price_lower_bound=positive_price_floor,
)

labor = GEMB.CommoditySpec(
    :labor;
    axes=(period=1:(np - 1),),
    price_lower_bound=positive_price_floor,
)

model = GEMB.GEMBModel(
    [
        product,
        labor,
    ];
    numeraire=GEMB.CommodityRef(
        :product;
        period=1,
    ),
    numeraire_value=1.0,
)

producer = GEMB.AgentTemplate(
    :producer,
    GEMB.CESSpec(
        [0.5, 0.5];
        es=1.0,
        alpha=2.0,
    );
    periods=1:(np - 1),
    demands=[
        GEMB.CommodityRef(
            :product;
            period=GEMB.RelativePeriod(0),
        ),
        GEMB.CommodityRef(
            :labor;
            period=GEMB.RelativePeriod(0),
        ),
    ],
    outputs=[
        GEMB.CommodityRef(
            :product;
            period=GEMB.RelativePeriod(1),
        ),
    ],
    activity_start=100.0,
)

GEMB.add_agents!(model, producer)

GEMB.add_agent!(
    model,
    GEMB.CESSpec(
        fill(1.0 / np, np);
        es=1.0,
        alpha=1.0,
    );
    demands=[
        GEMB.CommodityRef(:product),
    ],
    endowments=[
        GEMB.CommodityRef(
            :product;
            period=1,
        ),
        GEMB.CommodityRef(:labor),
    ],
    endowment_quantities=vcat(
        initial_product_endowment,
        fill(labor_endowment, np - 1),
    ),
    activity_start=100.0,
    name=:consumer,
)

result = GEMB.solve(
    model;
    p0=ones(2 * np - 1),
    residual_tol=1.0e-8,
    silent=true,
)

GEMB.print_equilibrium_statistics(model, result)

@assert result.solved
@assert result.mcp_solved
@assert result.all_markets_clear
@assert result.max_natural_residual <= 1.0e-7
@assert maximum(abs, result.total_net_supply) <= 1.0e-7
