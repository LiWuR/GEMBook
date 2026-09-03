using GeneralEquilibriumModeling


function gamma_from_payoff(expected_payoff, low_threshold, high_threshold)
    tol = 1.0e-10

    if expected_payoff > high_threshold + tol
        return 0.2
    elseif expected_payoff < low_threshold - tol
        return 0.8
    else
        return 0.4
    end
end


portfolio_expected_payoff(PMP, D) =
    vec(sum(PMP .* D; dims=1))


function main()
    Supply = [
        0.49  0.51
        0.49  0.51
    ]

    PMP = [
        120.0  120.0
        100.0  100.0
    ]

    PSD = [
        50.0  50.0
        10.0  10.0
    ]

    Cor = [
        1.0  0.0
        0.0  1.0
    ]

    payoff_benchmark = 110.0
    low_threshold = payoff_benchmark / 1.02
    high_threshold = payoff_benchmark * 1.02

    initial_expected_payoff =
        portfolio_expected_payoff(PMP, Supply)

    gamma =
        gamma_from_payoff.(
            initial_expected_payoff,
            low_threshold,
            high_threshold,
        )

    p0 = [1.0, 1.0]
    x0 = copy(Supply)
    lambda0 = ones(2)

    final_result = nothing
    final_expected_payoff = nothing
    iterations = 0

    seen = Set{Tuple{Float64,Float64}}()

    for iteration in 1:10
        iterations = iteration
        state = (gamma[1], gamma[2])

        state in seen && error(
            "Risk-aversion updating entered a cycle before reaching a fixed point."
        )
        push!(seen, state)

        result = GEMB.solve_asset_equilibrium_amsd(
            Supply=Supply,
            gamma=gamma,
            PMP=PMP,
            PSD=PSD,
            Cor=Cor,
            numeraire_index=2,
            numeraire_value=1.0,
            p0=p0,
            x0=x0,
            lambda0=lambda0,
            residual_tol=1.0e-8,
            silent=true,
        )

        result.solved || error(
            "The conditional AMSD asset equilibrium was not solved."
        )

        expected_payoff =
            portfolio_expected_payoff(PMP, result.D)

        new_gamma =
            gamma_from_payoff.(
                expected_payoff,
                low_threshold,
                high_threshold,
            )

        final_result = result
        final_expected_payoff = expected_payoff

        if new_gamma == gamma
            break
        end

        gamma = new_gamma
        p0 = copy(result.p)
        x0 = copy(result.D)
        lambda0 = copy(result.lambda)
    end

    final_result === nothing &&
        error("No equilibrium was computed.")

    @assert final_result.solved
    @assert final_result.kkt_passed
    @assert final_result.value_marginal_utility_conditions_passed

    initial_gap =
        maximum(initial_expected_payoff) -
        minimum(initial_expected_payoff)

    final_gap =
        maximum(final_expected_payoff) -
        minimum(final_expected_payoff)

    println("========== AMSD asset equilibrium ==========")
    println("Iterations:        ", iterations)
    println("Prices:            ", final_result.p)
    println("Holdings:")
    display(final_result.D)
    println("Expected payoffs:  ", final_expected_payoff)
    println("Gamma:             ", gamma)
    println("Payoff gap:        ", initial_gap, " -> ", final_gap)
    println("Run completed successfully.")

    return final_result
end


result = main()
nothing
