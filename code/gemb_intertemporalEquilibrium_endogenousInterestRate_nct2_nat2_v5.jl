# GEMB high-level framework: four-period pure-exchange equilibrium
# with endogenous interest rates.
using GeneralEquilibriumModeling

beta = [0.4, 0.3, 0.2, 0.1]
labor_endowment = fill(100.0, 4)
money_endowment = ones(4)

positive_price_floor = 1.0e-10

labor = GEMB.CommoditySpec(
    :labor;
    axes=(period=1:3,),
    price_lower_bound=positive_price_floor,
)

money = GEMB.CommoditySpec(
    :money;
    axes=(period=1:4,),
    price_lower_bound=positive_price_floor,
)

model = GEMB.GEMBModel(
    [
        labor,
        :labor_4,
        money,
    ];
    numeraire=GEMB.CommodityRef(
        :labor;
        period=1,
    ),
    numeraire_value=1.0,
)

interest_rate_spec = GEMB.ConditionAgentSpec(
    (variables, observed_values) -> begin
        r1, r2, r3, terminal_interest_inclusive_price = variables
        p_money1, p_money2, p_money3, p_money4 = observed_values

        return [
            r1 - p_money1 / (p_money2 + p_money3 + p_money4),
            r2 - p_money2 / (p_money3 + p_money4),
            r3 - p_money3 / p_money4,
            terminal_interest_inclusive_price - p_money4 / labor_endowment[4],
        ]
    end,
)

GEMB.add_agent!(
    model,
    interest_rate_spec;
    variable_names=[
        :r1,
        :r2,
        :r3,
        :terminal_interest_inclusive_price,
    ],
    variable_start=1.0,
    variable_lower_bounds=[
        0.0,
        0.0,
        0.0,
        positive_price_floor,
    ],
    variable_upper_bounds=Inf,
    observed_variables=[
        GEM.PriceVariableRef(:money_1),
        GEM.PriceVariableRef(:money_2),
        GEM.PriceVariableRef(:money_3),
        GEM.PriceVariableRef(:money_4),
    ],
    name=:interestRateDeterminer,
)

consumer_spec = GEMB.MarshallDemandConsumerSpec(
    function (income, prices, observed_values)
        rates = observed_values[1:3]
        terminal_interest_inclusive_price = observed_values[4]

        p_labor = prices[1:4]
        p_money = prices[5:8]

        labor_demand =
            beta[1:3] .* income ./
            (p_labor[1:3] .* (1 .+ rates))

        money_demand =
            rates .* beta[1:3] .* income ./
            ((1 .+ rates) .* p_money[1:3])

        labor4_demand =
            beta[4] * income / terminal_interest_inclusive_price

        money4_demand =
            beta[4] * income *
            (terminal_interest_inclusive_price - p_labor[4]) /
            (terminal_interest_inclusive_price * p_money[4])

        return vcat(
            labor_demand,
            labor4_demand,
            money_demand,
            money4_demand,
        )
    end,
)

observed_interest_variables = [
    GEMB.agent_variable_ref(
        :interestRateDeterminer,
        :r1,
    ),
    GEMB.agent_variable_ref(
        :interestRateDeterminer,
        :r2,
    ),
    GEMB.agent_variable_ref(
        :interestRateDeterminer,
        :r3,
    ),
    GEMB.agent_variable_ref(
        :interestRateDeterminer,
        :terminal_interest_inclusive_price,
    ),
]

all_commodities = [
    GEMB.CommodityRef(:labor),
    :labor_4,
    GEMB.CommodityRef(:money),
]

GEMB.add_agent!(
    model,
    consumer_spec;
    demands=all_commodities,
    endowments=[
        GEMB.CommodityRef(:labor),
        :labor_4,
    ],
    endowment_quantities=labor_endowment,
    observed_variables=observed_interest_variables,
    name=:laborer,
)

GEMB.add_agent!(
    model,
    consumer_spec;
    demands=all_commodities,
    endowments=GEMB.CommodityRef(:money),
    endowment_quantities=money_endowment,
    observed_variables=observed_interest_variables,
    name=:moneyOwner,
)

result = GEMB.solve(
    model;
    p0=ones(8),
    residual_tol=1.0e-8,
    silent=true,
)

interest_variables =
    result.agent_variable_values[model.agent_index[:interestRateDeterminer]]

GEMB.print_equilibrium_statistics(model, result)

println()
println("Primitive interest rates:          ", interest_variables[1:3])
println("Terminal interest-inclusive price: ", interest_variables[4])
