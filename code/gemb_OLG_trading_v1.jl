using GeneralEquilibriumModeling

const GEM = GeneralEquilibriumModeling.GEM
const GEMB = GeneralEquilibriumModeling.GEMB

np = 6
omega = 100.0
product(t) = GEMB.CommodityRef(:product; period=t)

function build_model(q0, beta0)
    model = GEMB.GEMBModel(
        [
            GEMB.CommoditySpec(
                :product;
                axes=(period=1:np,),
                price_lower_bound=1.0e-10,
            ),
        ];
        numeraire=product(1),
    )

    # q and endpoint preference shares
    GEMB.add_agent!(
        model,
        GEMB.ConditionAgentSpec(
            (v, p) -> begin
                q = exp(v[1])
                [p[t + 1] - q * p[t] for t in 1:(np - 1)]
            end,
        );
        variable_names=[:log_q, :beta1, :beta2, :beta_bar1, :beta_bar2],
        variable_start=[log(q0); beta0],
        variable_lower_bounds=-Inf,
        variable_upper_bounds=Inf,
        observed_variables=[
            GEM.PriceVariableRef(Symbol(:product_, t))
            for t in 1:np
        ],
        name=:steady_state,
    )

    # Consumer 1
    GEMB.add_agent!(
        model,
        GEMB.MarshallDemandConsumerSpec(
            (w, p, b) -> [
                b[1] * w / p[1],
                b[2] * w / p[2],
                (1 - b[1] - b[2]) * w / p[3],
            ],
        );
        demands=product.(1:3),
        endowments=product.(1:2),
        endowment_quantities=fill(omega, 2),
        observed_variables=[
            GEM.AgentVariableRef(:steady_state, :beta1),
            GEM.AgentVariableRef(:steady_state, :beta2),
        ],
        name=:consumer1,
    )

    # Consumers 2--4
# Consumers 2--4
for i in 2:4
    GEMB.add_agent!(
        model,
        GEMB.CESSpec(fill(1 / 3, 3));
        demands=product.(i:(i + 2)),
        endowments=product.(i:(i + 1)),
        endowment_quantities=fill(omega, 2),
        name=Symbol(:consumer, i),
    )
end

    # Consumer 5
    GEMB.add_agent!(
        model,
        GEMB.MarshallDemandConsumerSpec(
            (w, p, b) -> [
                b[1] * w / p[1],
                b[2] * w / p[2],
                (1 - b[1] - b[2]) * w / p[3],
            ],
        );
        demands=[product(5), product(6), product(1)],
        endowments=product.(5:6),
        endowment_quantities=fill(omega, 2),
        observed_variables=[
            GEM.AgentVariableRef(:steady_state, :beta_bar1),
            GEM.AgentVariableRef(:steady_state, :beta_bar2),
        ],
        name=:consumer5,
    )

    return model
end

function solve_case(q0, beta0)
    model = build_model(q0, beta0)

    result = GEMB.solve(
        model;
        p0=q0 .^ (0:(np - 1)),
        silent=true,
    )

    i = model.agent_index[:steady_state]
    v = result.agent_variable_values[i]

    q = exp(v[1])
    beta1, beta2, beta_bar1, beta_bar2 = v[2:5]

    println("\nq = ", q)
    println("p = ", result.prices)
    println("beta = ", [beta1, beta2, beta_bar1, beta_bar2])

    GEMB.print_equilibrium_statistics(model, result)

    return result
end

# Time-circle equilibrium
circle = solve_case(
    0.5,
    fill(0.1, 4),
)

# Time-line equilibrium
line = solve_case(
    2.0,
    fill(0.1, 4),
)

nothing