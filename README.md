# GeneralEquilibriumModeling.jl and Structural Equilibrium Models

## A Cookbook

This repository contains the source files and companion programs for the book *GeneralEquilibriumModeling.jl and Structural Equilibrium Models: A Cookbook*.

**Read the book online:**
https://liwur.github.io/GEMBook/

## About the Book

The book develops a unified approach to general equilibrium modeling based on structural equilibrium models, with computational implementations provided by the Julia package [GeneralEquilibriumModeling.jl](https://github.com/LiWuR/GeneralEquilibriumModeling.jl). It studies both the theoretical structure of equilibrium models and their computational representation, with applications involving production, consumption, taxation, assets, money, intertemporal equilibrium, joint production, and other economic mechanisms.

A central theme of the book is that a wide range of general equilibrium models can be represented systematically in terms of commodities, economic agents, activity levels, revenue-expenditure balance conditions, supply-demand balance conditions (i.e., market-clearing conditions), and complementarity relations.

The `code/` directory contains Julia programs corresponding to examples developed in the book.

In general, the examples follow the progression

**economic model → equilibrium formulation → computational representation → numerical solution**.

Because the book and the package are developed together, some examples also illustrate newly introduced or extended modeling capabilities of `GeneralEquilibriumModeling.jl`.
