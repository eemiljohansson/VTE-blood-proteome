# Libraries

library(dplyr)
library(tidyr)
library(ggplot2)
library(ggridges)
library(patchwork)


# Function: Cohort data builder
build_cohort_data <- function(
    metadata,
    cohorts,
    cohort_order = names(cohorts)
) {
  
  required <- c("DAid", "Disease")
  
  if (!all(required %in% names(metadata))) {
    stop("metadata must contain DAid and Disease.")
  }
  
  if (
    !is.list(cohorts) ||
    is.null(names(cohorts)) ||
    anyNA(names(cohorts)) ||
    any(names(cohorts) == "") ||
    anyDuplicated(names(cohorts))
  ) {
    stop("cohorts must be a list with unique, non-empty names.")
  }
  
  if (
    length(cohort_order) == 0L ||
    anyNA(cohort_order) ||
    anyDuplicated(cohort_order) ||
    !all(cohort_order %in% names(cohorts))
  ) {
    stop("cohort_order must contain unique names from cohorts.")
  }
  
  # Retain only requested cohorts
  cohorts <- cohorts[cohort_order]
  
  result <- bind_rows(
    lapply(names(cohorts), function(cohort_name) {
      
      metadata |>
        filter(
          !is.na(DAid),
          !is.na(Disease),
          Disease %in% cohorts[[cohort_name]]
        ) |>
        mutate(Cohort = cohort_name)
      
    })
  )
  
  if (nrow(result) == 0L) {
    stop("No participants matched the requested cohorts.")
  }
  
  # Avoid silently choosing between conflicting duplicate records
  result <- result |>
    distinct()
  
  if (anyDuplicated(result[c("DAid", "Cohort")])) {
    stop(
      "Multiple different records exist for the same DAid within a cohort. ",
      "Resolve these duplicates before plotting."
    )
  }
  
  result |>
    mutate(
      Cohort = factor(Cohort, levels = rev(cohort_order))
    )
}

# Age distribution
plot_age_distribution <- function(
    metadata,
    cohorts,
    cohort_order = names(cohorts),
    age_var = "Age",
    cohort_colors = NULL,
    base_size = 14
) {
  
  if (!age_var %in% names(metadata)) {
    stop("Age column not found: ", age_var)
  }
  
  if (!is.numeric(metadata[[age_var]])) {
    stop("The selected age column must be numeric.")
  }
  
  df <- build_cohort_data(
    metadata = metadata,
    cohorts = cohorts,
    cohort_order = cohort_order
  ) |>
    mutate(Age_use = .data[[age_var]]) |>
    filter(is.finite(Age_use))
  
  if (nrow(df) == 0L) {
    stop("No finite age values are available.")
  }
  
  # Density estimation requires at least two distinct ages
  density_cohorts <- df |>
    group_by(Cohort) |>
    summarise(
      n = n(),
      distinct_ages = n_distinct(Age_use),
      .groups = "drop"
    ) |>
    filter(n >= 2, distinct_ages >= 2) |>
    pull(Cohort) |>
    as.character()
  
  df_density <- df |>
    filter(as.character(Cohort) %in% density_cohorts)
  
  # Display individual points when a density cannot be estimated
  df_points <- df |>
    filter(!as.character(Cohort) %in% density_cohorts)
  
  p <- ggplot(
    df,
    aes(x = Age_use, y = Cohort, fill = Cohort)
  )
  
  if (nrow(df_density) > 0L) {
    p <- p +
      geom_density_ridges(
        data = df_density,
        scale = 1.15,
        alpha = 0.75,
        rel_min_height = 0.01,
        linewidth = 0.35,
        colour = "grey30",
        quantile_lines = TRUE,
        quantiles = 2
      )
  }
  
  if (nrow(df_points) > 0L) {
    p <- p +
      geom_point(
        data = df_points,
        shape = 21,
        size = 3,
        colour = "grey30"
      )
  }
  
  p <- p +
    scale_y_discrete(drop = FALSE) +
    labs(
      x = paste0(age_var, " (years)"),
      y = NULL
    ) +
    theme_classic(base_size = base_size) +
    theme(
      legend.position = "none",
      axis.text.y = element_text(colour = "grey15")
    )
  
  if (!is.null(cohort_colors)) {
    if (!all(cohort_order %in% names(cohort_colors))) {
      stop("cohort_colors must provide a named colour for every selected cohort.")
    }
    
    p <- p +
      scale_fill_manual(
        values = cohort_colors,
        drop = FALSE
      )
  }
  
  p
}


# Function: Sex distribution
plot_sex_distribution <- function(
    metadata,
    cohorts,
    cohort_order = names(cohorts),
    sex_var = "Sex",
    sex_order = c("Female", "Male", "Unknown"),
    sex_colors = c(
      "Female"  = "#B4678D",
      "Male"    = "#397DA8",
      "Unknown" = "#999999"
    ),
    base_size = 14,
    show_segment_counts = TRUE,
    show_total = TRUE
) {
  
  if (!sex_var %in% names(metadata)) {
    stop("Sex column not found: ", sex_var)
  }
  
  if (
    anyNA(sex_order) ||
    anyDuplicated(sex_order) ||
    !"Unknown" %in% sex_order
  ) {
    stop("sex_order must contain unique labels and include 'Unknown'.")
  }
  
  df <- build_cohort_data(
    metadata = metadata,
    cohorts = cohorts,
    cohort_order = cohort_order
  ) |>
    mutate(
      Sex_raw = trimws(as.character(.data[[sex_var]])),
      
      # Standardize common text labels.
      # Numeric codes are deliberately not assumed.
      Sex_plot = case_when(
        is.na(Sex_raw) | Sex_raw == "" ~ "Unknown",
        tolower(Sex_raw) %in% c("f", "female", "woman", "women") ~ "Female",
        tolower(Sex_raw) %in% c("m", "male", "man", "men") ~ "Male",
        tolower(Sex_raw) %in% c(
          "unknown", "missing", "na", "n/a", "not reported"
        ) ~ "Unknown",
        TRUE ~ Sex_raw
      )
    )
  
  unexpected <- setdiff(unique(df$Sex_plot), sex_order)
  
  if (length(unexpected) > 0L) {
    stop(
      "Sex values not included in sex_order: ",
      paste(unexpected, collapse = ", "),
      ". Recode these values or update sex_order and sex_colors."
    )
  }
  
  if (!all(sex_order %in% names(sex_colors))) {
    stop("sex_colors must provide a named colour for every sex_order label.")
  }
  
  df_sex <- df |>
    mutate(
      Sex_plot = factor(Sex_plot, levels = sex_order)
    ) |>
    count(Cohort, Sex_plot, name = "n", .drop = FALSE) |>
    group_by(Cohort) |>
    mutate(
      total = sum(n),
      prop = if_else(total > 0, n / total, 0)
    ) |>
    ungroup()
  
  df_totals <- df_sex |>
    distinct(Cohort, total) |>
    filter(total > 0)
  
  p <- ggplot(
    df_sex,
    aes(x = n, y = Cohort, fill = Sex_plot)
  ) +
    geom_col(
      width = 0.72,
      colour = "white",
      linewidth = 0.35,
      position = position_stack(reverse = TRUE)
    ) +
    scale_fill_manual(
      values = sex_colors,
      breaks = sex_order,
      drop = FALSE,
      name = NULL
    ) +
    scale_y_discrete(drop = FALSE) +
    scale_x_continuous(
      labels = scales::label_comma(),
      expand = expansion(mult = c(0, if (show_total) 0.20 else 0.03))
    ) +
    labs(
      x = "Number of participants",
      y = NULL
    ) +
    theme_classic(base_size = base_size) +
    theme(
      legend.position = "bottom",
      axis.text.y = element_text(colour = "grey15")
    )
  
  if (show_segment_counts) {
    p <- p +
      geom_text(
        aes(label = if_else(n > 0, as.character(n), "")),
        position = position_stack(
          vjust = 0.5,
          reverse = TRUE
        ),
        colour = "white",
        fontface = "bold",
        size = 3.5
      )
  }
  
  if (show_total) {
    p <- p +
      geom_text(
        data = df_totals,
        aes(
          x = total,
          y = Cohort,
          label = paste0("n = ", total)
        ),
        inherit.aes = FALSE,
        hjust = -0.15,
        colour = "grey20",
        size = 3.5
      )
  }
  
  p
}

# Function: Sex distribution — equal-length bars with percentage x-axis
plot_sex_distribution <- function(
    metadata,
    cohorts,
    cohort_order = names(cohorts),
    sex_var = "Sex",
    sex_order = c("Female", "Male", "Unknown"),
    sex_colors = c(
      "Female"  = "#B4678D",
      "Male"    = "#397DA8",
      "Unknown" = "#999999"
    ),
    base_size = 14,
    show_total = TRUE
) {
  
  # ----------------------------------------------------------
  # Validate inputs
  # ----------------------------------------------------------
  
  if (!sex_var %in% names(metadata)) {
    stop("Sex column not found: ", sex_var)
  }
  
  if (
    anyNA(sex_order) ||
    anyDuplicated(sex_order) ||
    !"Unknown" %in% sex_order
  ) {
    stop("sex_order must contain unique labels and include 'Unknown'.")
  }
  
  if (!all(sex_order %in% names(sex_colors))) {
    stop(
      "sex_colors must provide a named colour for every sex_order label."
    )
  }
  
  # ----------------------------------------------------------
  # Build cohort membership and standardize sex labels
  # ----------------------------------------------------------
  
  df <- build_cohort_data(
    metadata = metadata,
    cohorts = cohorts,
    cohort_order = cohort_order
  ) |>
    dplyr::mutate(
      Sex_raw = trimws(as.character(.data[[sex_var]])),
      
      Sex_plot = dplyr::case_when(
        is.na(Sex_raw) | Sex_raw == "" ~ "Unknown",
        
        tolower(Sex_raw) %in%
          c("f", "female", "woman", "women") ~ "Female",
        
        tolower(Sex_raw) %in%
          c("m", "male", "man", "men") ~ "Male",
        
        tolower(Sex_raw) %in%
          c("unknown", "missing", "na", "n/a", "not reported") ~
          "Unknown",
        
        TRUE ~ Sex_raw
      ),
      
      # Requested order displayed from top to bottom
      Cohort = factor(
        as.character(Cohort),
        levels = rev(cohort_order)
      )
    )
  
  unexpected <- setdiff(unique(df$Sex_plot), sex_order)
  
  if (length(unexpected) > 0L) {
    stop(
      "Sex values not included in sex_order: ",
      paste(unexpected, collapse = ", "),
      ". Recode these values or update sex_order and sex_colors."
    )
  }
  
  # ----------------------------------------------------------
  # Calculate counts and within-cohort proportions
  # ----------------------------------------------------------
  
  df_sex <- df |>
    dplyr::mutate(
      Sex_plot = factor(Sex_plot, levels = sex_order)
    ) |>
    dplyr::count(
      Cohort,
      Sex_plot,
      name = "n",
      .drop = FALSE
    ) |>
    dplyr::group_by(Cohort) |>
    dplyr::mutate(
      total = sum(n),
      prop = n / pmax(total, 1)
    ) |>
    dplyr::ungroup()
  
  df_totals <- df_sex |>
    dplyr::distinct(Cohort, total)
  
  # ----------------------------------------------------------
  # Plot
  # ----------------------------------------------------------
  
  p <- ggplot2::ggplot(
    df_sex,
    ggplot2::aes(
      x = prop,
      y = Cohort,
      fill = Sex_plot
    )
  ) +
    ggplot2::geom_col(
      width = 0.72,
      colour = "white",
      linewidth = 0.35,
      position = ggplot2::position_stack(reverse = TRUE),
      orientation = "y"
    ) +
    ggplot2::scale_fill_manual(
      values = sex_colors,
      breaks = sex_order,
      drop = FALSE,
      name = NULL
    ) +
    ggplot2::scale_y_discrete(drop = FALSE) +
    ggplot2::scale_x_continuous(
      limits = c(0, 1),
      breaks = seq(0, 1, by = 0.25),
      labels = scales::label_percent(accuracy = 1),
      expand = ggplot2::expansion(mult = c(0, 0)),
      # Allow total-count labels beyond 100%
      oob = scales::oob_keep
    ) +
    ggplot2::coord_cartesian(
      xlim = c(0, 1),
      clip = "off"
    ) +
    ggplot2::labs(
      x = "Sex distribution (%)",
      y = NULL
    ) +
    ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(
      legend.position = "top",
      axis.text.y = ggplot2::element_text(colour = "grey15"),
      axis.text.x = ggplot2::element_text(colour = "grey15"),
      plot.margin = ggplot2::margin(
        t = 10,
        r = if (show_total) 95 else 10,
        b = 10,
        l = 10
      )
    )
  
  # ----------------------------------------------------------
  # Total counts aligned outside the bars
  # ----------------------------------------------------------
  
  if (show_total) {
    p <- p +
      ggplot2::geom_text(
        data = df_totals,
        ggplot2::aes(
          x = 1.04,
          y = Cohort,
          label = paste0(
            "n = ",
            scales::comma(total, accuracy = 1)
          )
        ),
        inherit.aes = FALSE,
        hjust = 0,
        colour = "grey20",
        size = 3.5
      )
  }
  
  p
}

# Function: boxplots
plot_protein_boxplots <- function(
    data_long,
    metadata,
    highlighted_proteins,
    cohorts,
    cohort_order = names(cohorts),
    cohort_colors,
    exclude_classes = "Pediatric",
    ncol = 2,
    scales = "free_y",
    base_size = 14,
    point_size = 1.3,
    point_alpha = 0.5
) {
  
  # ----------------------------------------------------------
  # Validate inputs
  # ----------------------------------------------------------
  
  if (!all(c("DAid", "Feature", "NPX") %in% names(data_long))) {
    stop("data_long must contain DAid, Feature and NPX.")
  }
  
  if (!is.numeric(data_long$NPX)) {
    stop("NPX must be numeric.")
  }
  
  if (!length(highlighted_proteins) ||
      anyNA(highlighted_proteins) ||
      anyDuplicated(highlighted_proteins)) {
    stop("highlighted_proteins must contain unique, non-missing names.")
  }
  
  if (!all(cohort_order %in% names(cohort_colors))) {
    stop("cohort_colors must contain a named colour for each selected cohort.")
  }
  
  if (!requireNamespace("ggbeeswarm", quietly = TRUE)) {
    stop("Please install ggbeeswarm: install.packages('ggbeeswarm')")
  }
  
  # ----------------------------------------------------------
  # Filter metadata before constructing overlapping cohorts
  # ----------------------------------------------------------
  
  metadata_use <- metadata
  
  if (length(exclude_classes) > 0L) {
    
    if (!"Class" %in% names(metadata_use)) {
      stop("metadata must contain Class when exclude_classes is used.")
    }
    
    metadata_use <- metadata_use |>
      dplyr::filter(
        is.na(Class) | !Class %in% exclude_classes
      )
  }
  
  # Uses your existing helper
  membership <- build_cohort_data(
    metadata = metadata_use,
    cohorts = cohorts,
    cohort_order = cohort_order
  ) |>
    dplyr::select(DAid, Cohort) |>
    dplyr::distinct()
  
  # ----------------------------------------------------------
  # Select protein measurements
  # ----------------------------------------------------------
  
  protein_data <- data_long |>
    dplyr::select(DAid, Feature, NPX) |>
    dplyr::filter(
      Feature %in% highlighted_proteins,
      is.finite(NPX)
    )
  
  # Prevent accidental duplication of measurements
  if (anyDuplicated(protein_data[c("DAid", "Feature")])) {
    stop(
      "Multiple measurements exist for a DAid–Feature combination. ",
      "Resolve replicates before plotting."
    )
  }
  
  # Each sample contributes to every cohort it belongs to
  plot_data <- membership |>
    dplyr::inner_join(
      protein_data,
      by = "DAid",
      relationship = "many-to-many"
    ) |>
    dplyr::mutate(
      Cohort = factor(
        as.character(Cohort),
        levels = cohort_order
      ),
      Feature = factor(
        Feature,
        levels = highlighted_proteins
      )
    )
  
  if (nrow(plot_data) == 0L) {
    stop("No matching protein measurements were found for the selected cohorts.")
  }
  
  missing_proteins <- setdiff(
    highlighted_proteins,
    as.character(unique(plot_data$Feature))
  )
  
  if (length(missing_proteins) > 0L) {
    warning(
      "No finite measurements found for: ",
      paste(missing_proteins, collapse = ", ")
    )
  }
  
  # ----------------------------------------------------------
  # Plot
  # ----------------------------------------------------------
  
  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = Cohort,
      y = NPX,
      fill = Cohort
    )
  ) +
    ggbeeswarm::geom_quasirandom(
      shape = 21,
      colour = "black",
      size = point_size,
      alpha = point_alpha,
      stroke = 0,
      width = 0.25,
      show.legend = FALSE
    ) +
    ggplot2::geom_boxplot(
      width = 0.55,
      colour = "black",
      outlier.shape = NA,
      alpha = 0.65,
      show.legend = FALSE
    ) +
    ggplot2::facet_wrap(
      ~ Feature,
      ncol = ncol,
      scales = scales
    ) +
    ggplot2::scale_fill_manual(
      values = cohort_colors,
      drop = FALSE
    ) +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::labs(
      x = "Cohort",
      y = "Protein abundance (NPX)"
    ) +
    ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      ),
      strip.text = ggplot2::element_text(face = "bold"),
      legend.position = "none"
    )
}

