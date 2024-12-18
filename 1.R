# Load required libraries
library(tidyverse)  # for data manipulation and visualization
library(effsize)    # for effect size calculations

# Load the data frame (already assumed to be annotated)
df <- sct_data_frame_with_annotations

# Filter the data to only include rows where cell_Type is 'Microglia' and remove the first and last columns, then omit NA values
df_filtered = df[df$cell_Type == "Microglia", -c(1, ncol(df))] %>% na.omit()

# Separate the data into old and young groups, excluding the 'Group' and 'Mouse_ID' columns
df_old = df_filtered %>% filter(Group == "Old") %>% select(-c(Group, Mouse_ID))
df_yo = df_filtered %>% filter(Group == "Young") %>% select(-c(Group, Mouse_ID))

# Also create a dataset excluding only 'Mouse_ID' for effect size calculation
df_eff = df_filtered %>% select(-Mouse_ID)

# Perform t-tests for each gene (column) between the 'Young' and 'Old' groups, and store the p-values
p_values = sapply(1:ncol(df_old), FUN = function(x) {
  t.test(df_yo[, x], df_old[, x])$p.value
})

# Calculate Cohen's d effect size for each gene between the groups
effect_size = sapply(1:ncol(df_old), FUN = function(x) {
  cohen.d(df_eff[, x], df_eff[, "Group"])
})

# Adjust the p-values for multiple testing
adj_pvals = p.adjust(p_values)

# Create a data frame to store the adjusted p-values and corresponding gene names
p_val_df = data.frame(
  "adj_pval" = adj_pvals,
  "genes" = colnames(df_old)
) %>% mutate(`-log10(pval)` = -log10(adj_pvals))

# Plot the top 20 genes by adjusted p-values using a bar plot
p_val_df %>%
  head(20) %>%  # Select the top 20 genes
  ggplot(., aes(x = `-log10(pval)`, y = reorder(genes, `-log10(pval)`))) +  # Create a ggplot object
  geom_bar(stat = "identity") +  # Add a bar plot layer
  labs(
    x = "-log10(p_val)",  # X-axis label
    y = "Genes",          # Y-axis label
    title = "Top 20 Genes by Adjusted P-Value")  # Plot title