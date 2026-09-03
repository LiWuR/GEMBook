using GeneralEquilibriumModeling

beta = [0.5, 0.25, 0.25]
omega = 100.0

# Degree-one homogenization:
# g(x1, x2, x_4) = (x1^2 + x2^2) / x_4.
production_function = inputs -> begin
    x1, x2, x_4 = inputs
    (x1^2 + x2^2) / x_4
end

# Scaled marginal product function:
# the common strictly positive factor 1 / x_4 is omitted.
marginal_product_function = inputs -> begin
    x1, x2, x_4 = inputs
    [2.0 * x1, 2.0 * x2, -(x1^2 + x2^2) / x_4]
end

cases = [
    ([60.0, 60.0], [1.0, 100.0, 100.0, -5000.0]),
    ([30.0, 70.0], [1.0, 60.0, 140.0, -5000.0]),
    ([70.0, 30.0], [1.0, 140.0, 60.0, -5000.0]),
]

function solve_case(case_id, input_start, p0)
    x1_start, x2_start = input_start

    model = GEMB.GEMBModel(
        [
            :product,
            GEMB.CommoditySpec(:labor; price_lower_bound=1.0e-10),
            GEMB.CommoditySpec(:land; price_lower_bound=1.0e-10),
            GEMB.CommoditySpec(
                :scale_claim;
                price_lower_bound=-Inf,
                price_upper_bound=Inf,
            ),
        ];
        numeraire=:product,
        numeraire_value=1.0,
    )

    GEMB.add_agent!(
        model,
        GEMB.ProductionFunctionSpec(
            production_function,
            marginal_product_function;
            behavior=:stationary,
        );
        outputs=:product,
        demands=[:labor, :land, :scale_claim],
        activity_start=x1_start^2 + x2_start^2,
        demand_start=[x1_start, x2_start, 1.0],
        demand_lower_bounds=[1.0e-10, 1.0e-10, 1.0e-10],
        production_multiplier_start=1.0,
        name=:firm,
    )

    GEMB.add_agent!(
        model,
        GEMB.CESSpec(beta; es=1.0, alpha=1.0);
        demands=[:product, :labor, :land],
        endowments=[:labor, :land, :scale_claim],
        endowment_quantities=[omega, omega, 1.0],
        name=:consumer,
    )

    result = GEMB.solve(
        model;
        p0=p0,
        residual_tol=1.0e-8,
        silent=true,
    )

    # Firm variables: output, labor, land, scale claim, multiplier.
    _, x1, x2, x_4, _ = result.agent_variable_values[1] 
    p = result.prices

    claim_rate =
        p[4] * x_4 /
        (p[2] * x1 + p[3] * x2)

    @assert result.solved
    @assert result.mcp_solved
    @assert result.all_markets_clear
    @assert isapprox(x_4, 1.0; atol=1.0e-6, rtol=1.0e-6)
    @assert isapprox(claim_rate, -0.5; atol=1.0e-6, rtol=1.0e-6)

    println("\n================ Case $case_id ================")
    println("Starting inputs = ", input_start)
    println("Starting prices = ", p0)

    GEMB.print_equilibrium_statistics(model, result)

    println("\nProduction inputs:")
    println("labor input = ", x1)
    println("land input = ", x2)
    println("scale-claim input x_4 = ", x_4)

    println("\nImplied scale-claim rate = ", claim_rate)

    return result
end

solutions = [
    solve_case(i, case...)
    for (i, case) in enumerate(cases)
]

nothing
