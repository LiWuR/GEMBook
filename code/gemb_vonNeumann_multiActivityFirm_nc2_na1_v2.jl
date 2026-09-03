using GeneralEquilibriumModeling

A = [
    0.8  0.5  0.06
    2.0  2.0  0.40
]

B = [
    1.0  1.0  0.0
    0.0  0.0  1.0
]

model = GEMB.GEMBModel(
    [:wheat, :iron];
    numeraire=:wheat,
    numeraire_value=1.0,
)

GEMB.add_net_supply_agent!(
    model,
    function (variables, prices, observed_values)
        z = variables
        rho = observed_values[1]

        return (rho .* B - A) * z
    end;
    commodities=[:wheat, :iron],
    variable_names=[:activity1, :activity2, :activity3],
    variable_lower_bounds=[0.0, 0.0, 0.0],
    variable_upper_bounds=[Inf, Inf, Inf],
    variable_start=[100.0, 100.0, 100.0],
    observed_variables=[
        GEM.AgentVariableRef(:growth_condition, :rho),
    ],
    condition_rule=GEM.UnitRevenueExpenditureBalanceConditions(),
    name=:firm,
)

GEMB.add_agent!(
    model,
    GEMB.ConditionAgentSpec(
        (variables, observed_values) -> [
            sum(observed_values) - 600.0,
        ],
    );
    variable_names=[:rho],
    variable_start=[0.8],
    variable_lower_bounds=[0.0],
    variable_upper_bounds=[Inf],
    observed_variables=[
        GEM.AgentVariableRef(:firm, :activity1),
        GEM.AgentVariableRef(:firm, :activity2),
        GEM.AgentVariableRef(:firm, :activity3),
    ],
    name=:growth_condition,
)

result = GEMB.solve(
    model;
    p0=[1.0, 0.15],
    residual_tol=1.0e-8,
    silent=true,
)

prices = result.prices
activities = result.agent_variable_values[1]
rho_star = result.agent_variable_values[2][1]
growth_rate = inv(rho_star) - 1.0

println("Prices:      ", prices)
println("Activities:  ", activities)
println("rho:         ", rho_star)
println("Growth rate: ", growth_rate)

nothing
