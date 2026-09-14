library(ggplot2)

CSV_PATH <- "cv_results.csv"
OUT_DIR  <- "figures"

FONT <- ""

dir.create(OUT_DIR, showWarnings = FALSE)

COL_GA      <- "#2D69A0"
COL_BASE    <- "#C1651A"
COL_ALERT   <- "#BE372D"
COL_INK     <- "#2F3A4A"
COL_MUTED   <- "#7B838C"
COL_GRID    <- "#E3E5E8"
COL_BANDBG  <- "#F6E3E1"

theme_diss <- function(base_size = 9) {
  theme_minimal(base_size = base_size, base_family = FONT) +
    theme(
      panel.grid.minor   = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = COL_GRID, linewidth = 0.3),
      axis.title         = element_text(colour = COL_INK, size = base_size),
      axis.text          = element_text(colour = COL_MUTED, size = base_size - 1),
      plot.title         = element_text(colour = COL_INK, size = base_size + 1,
                                        face = "bold", hjust = 0),
      plot.subtitle      = element_text(colour = COL_MUTED, size = base_size - 0.5,
                                        hjust = 0, margin = margin(b = 8)),
      plot.caption       = element_text(colour = COL_MUTED, size = base_size - 1.5,
                                        hjust = 0, margin = margin(t = 8)),
      legend.position    = "top",
      legend.title       = element_blank(),
      legend.text        = element_text(colour = COL_INK, size = base_size - 1),
      legend.key.height  = unit(10, "pt"),
      plot.margin        = margin(6, 10, 6, 6)
    )
}

if (!file.exists(CSV_PATH)) {
  stop("Δεν βρέθηκε το ", CSV_PATH,
       " -- διόρθωσε το CSV_PATH στην αρχή του script.")
}

cv <- read.csv(CSV_PATH, stringsAsFactors = FALSE)

needed <- c("config", "fold", "mAP50")
if (!all(needed %in% names(cv))) {
  stop("Το CSV δεν έχει τις στήλες ", paste(needed, collapse = ", "),
       ". Βρέθηκαν: ", paste(names(cv), collapse = ", "))
}

cfgs <- sort(unique(cv$config))
if (length(cfgs) != 2) {
  stop("Περίμενα ακριβώς 2 configs (baseline, ga). Βρέθηκαν: ",
       paste(cfgs, collapse = ", "))
}

base_lab <- grep("base", cfgs, ignore.case = TRUE, value = TRUE)
ga_lab   <- setdiff(cfgs, base_lab)
if (length(base_lab) != 1) stop("Δεν ξεχώρισα το baseline config.")

w <- merge(
  data.frame(fold = cv$fold[cv$config == base_lab],
             baseline = cv$mAP50[cv$config == base_lab]),
  data.frame(fold = cv$fold[cv$config == ga_lab],
             ga = cv$mAP50[cv$config == ga_lab]),
  by = "fold"
)
w$diff <- w$ga - w$baseline
w$win  <- w$diff > 0

stopifnot(nrow(w) == length(unique(cv$fold)))

cat("\n================ ΕΛΕΓΧΟΣ ΕΝΑΝΤΙ ΤΟΥ ΚΕΦ. 4 ================\n")
cat(sprintf("folds                : %d            (Κεφ.4: 44)\n", nrow(w)))
cat(sprintf("baseline mean +- sd  : %.3f +- %.3f  (Κεφ.4: 0.422 +- 0.112)\n",
            mean(w$baseline), sd(w$baseline)))
cat(sprintf("GA       mean +- sd  : %.3f +- %.3f  (Κεφ.4: 0.524 +- 0.130)\n",
            mean(w$ga), sd(w$ga)))
cat(sprintf("mean paired diff     : %+.3f +- %.3f (Κεφ.4: +0.102 +- 0.077)\n",
            mean(w$diff), sd(w$diff)))
cat(sprintf("range of differences : %.3f to %+.3f (Κεφ.4: -0.093 to +0.300)\n",
            min(w$diff), max(w$diff)))
cat(sprintf("GA wins              : %d/%d (%.1f%%)  (Κεφ.4: 41/44, 93.2%%)\n",
            sum(w$win), nrow(w), 100 * mean(w$win)))
cat(sprintf("losses at folds      : %s        (Κεφ.4: 11, 34, 39)\n",
            paste(w$fold[!w$win], collapse = ", ")))
cat(sprintf("Cohen's d            : %.3f          (Κεφ.4: 1.32)\n",
            mean(w$diff) / sd(w$diff)))
tt <- t.test(w$ga, w$baseline, paired = TRUE)
cat(sprintf("paired t             : t(%d) = %.2f, p = %.1e  (Κεφ.4: t(43)=8.77, p=4.0e-11)\n",
            tt$parameter, tt$statistic, tt$p.value))
cat("============================================================\n\n")

ord        <- order(w$baseline)
w$pos      <- match(w$fold, w$fold[ord])
fold_labs  <- w$fold[ord]
loss_pos   <- w$pos[!w$win]

m_base <- mean(w$baseline); m_ga <- mean(w$ga)

p1a <- ggplot(w) +

  annotate("rect", xmin = -Inf, xmax = Inf,
           ymin = loss_pos - 0.5, ymax = loss_pos + 0.5,
           fill = COL_BANDBG) +

  geom_vline(xintercept = m_base, colour = COL_BASE,
             linetype = "dashed", linewidth = 0.35) +
  geom_vline(xintercept = m_ga, colour = COL_GA,
             linetype = "dashed", linewidth = 0.35) +

  geom_segment(aes(x = baseline, xend = ga, y = pos, yend = pos),
               colour = COL_MUTED, linewidth = 0.4) +
  geom_point(aes(x = baseline, y = pos, colour = "Baseline (default hyp.)"),
             size = 1.5, shape = 16) +
  geom_point(aes(x = ga, y = pos, colour = "GA-optimised"),
             size = 1.5, shape = 17) +

  annotate("text", x = m_base, y = nrow(w) + 0.9,
           label = sprintf("mean %.3f", m_base),
           colour = COL_BASE, size = 2.4, hjust = 1.05, family = FONT) +
  annotate("text", x = m_ga, y = nrow(w) + 0.9,
           label = sprintf("mean %.3f", m_ga),
           colour = COL_GA, size = 2.4, hjust = -0.05, family = FONT) +
  scale_y_continuous(breaks = seq_len(nrow(w)), labels = fold_labs,
                     expand = expansion(add = c(0.8, 1.8))) +
  scale_colour_manual(values = c("Baseline (default hyp.)" = COL_BASE,
                                 "GA-optimised" = COL_GA)) +
  guides(colour = guide_legend(override.aes = list(shape = c(16, 17), size = 2))) +
  scale_x_continuous(breaks = seq(0.1, 0.9, 0.1)) +

  coord_cartesian(xlim = c(0.10, 0.90), clip = "off") +
  labs(
    x = "mAP@0.5", y = "Cross-validation fold",
    title = "GA-optimised configuration wins 41 of 44 paired folds",

    subtitle = paste0("Ordered by baseline score, easiest at the top.\n",
                      "Shaded rows are the three folds the baseline won.")
  ) +
  theme_diss() +
  theme(axis.text.y = element_text(size = 4.6),
        panel.grid.major.x = element_line(colour = COL_GRID, linewidth = 0.25))

ggsave(file.path(OUT_DIR, "fig_cv_paired_folds.pdf"), p1a,
       width = 5.4, height = 7.4, device = "pdf")
ggsave(file.path(OUT_DIR, "fig_cv_paired_folds.png"), p1a,
       width = 5.4, height = 7.4, dpi = 300, bg = "white")

p1b <- ggplot(w, aes(x = diff)) +
  geom_histogram(aes(fill = win), binwidth = 0.025,
                 colour = "white", linewidth = 0.3) +
  geom_vline(xintercept = 0, colour = COL_INK, linewidth = 0.45) +
  geom_vline(xintercept = mean(w$diff), colour = COL_GA,
             linetype = "dashed", linewidth = 0.5) +
  annotate("text", x = mean(w$diff), y = Inf,
           label = sprintf("mean %+.3f", mean(w$diff)),
           colour = COL_GA, size = 2.7, hjust = -0.08, vjust = 1.8, family = FONT) +
  annotate("text", x = 0, y = Inf, label = "no difference",
           colour = COL_INK, size = 2.7, hjust = 1.08, vjust = 1.8, family = FONT) +
  scale_fill_manual(values = c("TRUE" = COL_GA, "FALSE" = COL_ALERT),
                    labels = c("TRUE" = "GA better", "FALSE" = "baseline better"),
                    breaks = c("TRUE", "FALSE")) +
  scale_x_continuous(breaks = seq(-0.10, 0.30, 0.05)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
  labs(
    x = "Per-fold difference in mAP@0.5  (GA - baseline)",
    y = "Folds",
    title = "The difference is large relative to its own spread",
    subtitle = sprintf(
      "n = %d paired folds.  Mean %+.3f +/- %.3f,  Cohen's d = %.2f.",
      nrow(w), mean(w$diff), sd(w$diff), mean(w$diff) / sd(w$diff))
  ) +
  theme_diss() +
  theme(panel.grid.major.y = element_line(colour = COL_GRID, linewidth = 0.3))

ggsave(file.path(OUT_DIR, "fig_cv_diff_histogram.pdf"), p1b,
       width = 5.4, height = 3.1, device = "pdf")
ggsave(file.path(OUT_DIR, "fig_cv_diff_histogram.png"), p1b,
       width = 5.4, height = 3.1, dpi = 300, bg = "white")

lad <- data.frame(
  label = c("Originals only (1,170), naive split, vanilla v5s",
            "Aug. x4, group-aware hold-out, default hyp.",
            "Aug. x4, group-aware hold-out, GA hyp.  (honest)",
            "Aug. x4, LEAKY file-level split, GA hyp.",
            "No split at all (train = validation)"),
  map50 = c(0.396, 0.413, 0.507, 0.735, 0.887),
  role  = c("neutral", "neutral", "champion", "leaky", "neutral"),
  panel = c("Compared here", "Compared here", "Compared here",
            "Compared here", "Diagnostic"),
  stringsAsFactors = FALSE
)
PUBLISHED <- 0.750

lad$label <- factor(lad$label, levels = lad$label[order(lad$map50)])
lad$panel <- factor(lad$panel, levels = c("Compared here", "Diagnostic"))

TOP <- factor("Compared here", levels = levels(lad$panel))

y_champ <- 3; y_leaky <- 4; y_mid <- 3.5

ann_arrow <- data.frame(panel = TOP, x = 0.507, xend = 0.735,
                        y = y_mid, yend = y_mid)
ann_gain  <- data.frame(panel = TOP, x = 0.621, y = y_mid, lab = "+0.228")
ann_pub   <- data.frame(panel = TOP, x = PUBLISHED, y = 0.42,
                        lab = "published 0.750\n(protocol undocumented)")

p2 <- ggplot(lad, aes(y = label)) +

  geom_vline(xintercept = PUBLISHED, colour = COL_ALERT,
             linetype = "dashed", linewidth = 0.45) +
  geom_segment(aes(x = 0, xend = map50, yend = label, colour = role),
               linewidth = 1.5, lineend = "round") +
  geom_point(aes(x = map50, colour = role), size = 2.6) +

  geom_label(aes(x = map50, label = sprintf("%.3f", map50)),
             hjust = -0.18, size = 2.6, colour = COL_INK, family = FONT,
             fill = "white", label.size = 0, label.padding = unit(1.2, "pt")) +

  geom_segment(data = ann_arrow,
               aes(x = x, xend = xend, y = y, yend = yend),
               inherit.aes = FALSE, colour = COL_INK, linewidth = 0.4,
               arrow = arrow(ends = "both", length = unit(3.5, "pt"),
                             type = "closed")) +

  geom_label(data = ann_gain, aes(x = x, y = y, label = lab),
             inherit.aes = FALSE, fill = "white", label.size = 0,
             label.padding = unit(1.6, "pt"), size = 2.7,
             colour = COL_INK, fontface = "bold", family = FONT) +
  geom_label(data = ann_pub, aes(x = x, y = y, label = lab),
             inherit.aes = FALSE, colour = COL_ALERT, size = 2.3,
             hjust = 0.5, vjust = 0, lineheight = 0.95, family = FONT,
             fill = "white", label.size = 0, label.padding = unit(1.5, "pt")) +
  scale_colour_manual(values = c(champion = COL_GA,
                                 leaky    = COL_BASE,
                                 neutral  = COL_MUTED),
                      guide = "none") +
  scale_x_continuous(breaks = seq(0, 1, 0.1),
                     expand = expansion(mult = c(0, 0.06))) +
  coord_cartesian(xlim = c(0, 0.95), clip = "off") +
  facet_grid(panel ~ ., scales = "free_y", space = "free_y", switch = "y") +
  labs(
    x = "mAP@0.5", y = NULL,
    title = "One dataset, one model family, five evaluation setups",
    subtitle = paste0("The two coloured rows differ in one respect only:\n",
                      "whether the 90/10 split was drawn over groups or over files."),
    caption = paste0("The lower row is separated because it isolates nothing.\n",
                     "It also differs in hyperparameters, epoch budget and\n",
                     "checkpoint convention, and is included only to bound\n",
                     "what an undocumented evaluation could report.")
  ) +
  theme_diss() +
  theme(
    strip.placement   = "outside",
    strip.text.y.left = element_text(angle = 90, colour = COL_MUTED,
                                     size = 6, face = "bold"),
    axis.text.y       = element_text(colour = COL_INK, size = 6.6, hjust = 0),
    panel.spacing.y   = unit(9, "pt"),
    plot.title        = element_text(colour = COL_INK, size = 10, face = "bold"),
    plot.margin       = margin(6, 14, 6, 6)
  )

ggsave(file.path(OUT_DIR, "fig_protocol_sensitivity.pdf"), p2,
       width = 6.8, height = 3.6, device = "pdf")
ggsave(file.path(OUT_DIR, "fig_protocol_sensitivity.png"), p2,
       width = 6.8, height = 3.6, dpi = 300, bg = "white")

cat("Γράφτηκαν στο ./", OUT_DIR, "/ :\n",
    "  fig_cv_paired_folds.{pdf,png}\n",
    "  fig_cv_diff_histogram.{pdf,png}\n",
    "  fig_protocol_sensitivity.{pdf,png}\n", sep = "")

ga <- data.frame(
  generation = rep(1:5, 2),
  fitness    = c(0.581, 0.634, 0.634, 0.647, 0.674,
                 0.353, 0.517, 0.610, 0.632, 0.645),
  series     = rep(c("Best of generation", "Population mean"), each = 5)
)

p3 <- ggplot(ga, aes(x = generation, y = fitness,
                     colour = series, shape = series)) +

  geom_ribbon(data = data.frame(
                generation = 1:5,
                lo = c(0.353, 0.517, 0.610, 0.632, 0.645),
                hi = c(0.581, 0.634, 0.634, 0.647, 0.674)),
              aes(x = generation, ymin = lo, ymax = hi),
              inherit.aes = FALSE, fill = COL_GA, alpha = 0.08) +
  geom_line(linewidth = 0.6) +
  geom_point(size = 2.2) +

  scale_colour_manual(values = c("Best of generation" = COL_GA,
                                 "Population mean"    = COL_BASE)) +
  scale_shape_manual(values = c("Best of generation" = 16,
                                "Population mean"    = 17)) +
  scale_x_continuous(breaks = 1:5) +
  scale_y_continuous(limits = c(0.30, 0.72), breaks = seq(0.3, 0.7, 0.1)) +
  labs(x = "Generation", y = "Fitness (20-epoch validation mAP@0.5)",
       title = "The population converges, not just its leader",
       subtitle = paste0("Elitism guarantees the best-of-generation series ",
                         "cannot fall, so its rise is not\nevidence. The ",
                         "population mean closing on it is: the gap between ",
                         "them narrows by 87%.")) +
  theme_diss() +
  theme(panel.grid.major.y = element_line(colour = COL_GRID, linewidth = 0.3))

ggsave(file.path(OUT_DIR, "fig_ga_convergence.pdf"), p3,
       width = 5.0, height = 3.2, device = "pdf")
ggsave(file.path(OUT_DIR, "fig_ga_convergence.png"), p3,
       width = 5.0, height = 3.2, dpi = 300, bg = "white")

CURVE_DIR <- "."

cb <- read.csv(file.path(CURVE_DIR, "curves_FINAL_baseline.csv"), check.names = FALSE)
cg <- read.csv(file.path(CURVE_DIR, "curves_FINAL_ga.csv"),       check.names = FALSE)
names(cb) <- trimws(names(cb)); names(cg) <- trimws(names(cg))

cur <- rbind(
  data.frame(epoch = seq_len(nrow(cb)), mAP = cb[["metrics/mAP_0.5"]],
             config = "Baseline (default hyp.)"),
  data.frame(epoch = seq_len(nrow(cg)), mAP = cg[["metrics/mAP_0.5"]],
             config = "GA-optimised")
)
base_final <- cb[["metrics/mAP_0.5"]][nrow(cb)]
cross      <- which(cg[["metrics/mAP_0.5"]] >= base_final)[1]

cat(sprintf("\nΣΧΗΜΑ 4: baseline final = %.4f, το GA το φτανει στην εποχη %d\n",
            base_final, cross))

p4 <- ggplot(cur, aes(x = epoch, y = mAP, colour = config)) +
  geom_hline(yintercept = base_final, colour = COL_MUTED,
             linetype = "dashed", linewidth = 0.4) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = cross, colour = COL_INK,
             linetype = "dotted", linewidth = 0.4) +
  geom_point(data = data.frame(epoch = cross, mAP = base_final,
                               config = "GA-optimised"),
             size = 2.4, shape = 21, fill = "white", stroke = 0.9,
             show.legend = FALSE) +

  annotate("segment", x = cross + 1.5, xend = cross + 14,
           y = base_final - 0.02, yend = 0.155,
           colour = COL_MUTED, linewidth = 0.3) +
  annotate("text", x = cross + 15, y = 0.145,
           label = sprintf("epoch %d: the GA configuration matches\nthe baseline's final 100-epoch score",
                           cross),
           hjust = 0, vjust = 1, size = 2.5, colour = COL_INK, family = FONT,
           lineheight = 0.95) +
  scale_colour_manual(values = c("Baseline (default hyp.)" = COL_BASE,
                                 "GA-optimised" = COL_GA)) +
  scale_x_continuous(breaks = c(1, cross, seq(25, 100, 25))) +
  labs(x = "Training epoch", y = "Validation mAP@0.5",
       title = "The same result for less than a fifth of the compute",
       subtitle = sprintf(paste0("The baseline's final score after 100 epochs ",
                                 "is %.3f (dashed). The optimised\n",
                                 "configuration reaches it at epoch %d."),
                          base_final, cross)) +
  theme_diss() +
  theme(panel.grid.major.y = element_line(colour = COL_GRID, linewidth = 0.3))

ggsave(file.path(OUT_DIR, "fig_map_vs_epoch.pdf"), p4,
       width = 5.6, height = 3.3, device = "pdf")
ggsave(file.path(OUT_DIR, "fig_map_vs_epoch.png"), p4,
       width = 5.6, height = 3.3, dpi = 300, bg = "white")

cat("Προστεθηκαν: fig_ga_convergence.{pdf,png}, fig_map_vs_epoch.{pdf,png}\n")

md <- read.csv("santos_metadata.csv", stringsAsFactors = FALSE)
img <- md[!duplicated(md$stem), ]

INK <- "#2F3A4A"; GREY <- "#6B7280"
COL_M <- "#C1651A"; COL_N <- "#2D69A0"
th <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold", size = 11, colour = INK),
        axis.title = element_text(size = 9, colour = GREY),
        axis.text = element_text(size = 9, colour = INK),
        legend.position = "none")

per_year <- as.data.frame(table(img$year), stringsAsFactors = FALSE)
names(per_year) <- c("year", "n")
per_year$year <- factor(per_year$year)
pa <- ggplot(per_year, aes(year, n)) +
  geom_col(fill = COL_N, width = .65) +
  geom_text(aes(label = n), vjust = -0.4, size = 3.1, colour = INK) +
  scale_y_continuous(expand = expansion(mult = c(0, .15))) +
  labs(title = "(a) Images per survey year", x = NULL, y = "images") + th

obj <- md[md$cls != "", ]
cls <- as.data.frame(table(obj$cls), stringsAsFactors = FALSE)
names(cls) <- c("cls", "n")
cls$pct <- 100 * cls$n / sum(cls$n)
pb <- ggplot(cls, aes(cls, n, fill = cls)) +
  geom_col(width = .55) +
  geom_text(aes(label = sprintf("%d  (%.1f%%)", n, pct)), vjust = -0.4,
            size = 3.1, colour = INK) +
  scale_fill_manual(values = c(MILCO = COL_M, NOMBO = COL_N)) +
  scale_y_continuous(expand = expansion(mult = c(0, .18))) +
  labs(title = "(b) Annotated objects by class", x = NULL, y = "objects") + th

bg <- aggregate(background ~ year, img, function(v) c(sum(v), length(v)))
bgd <- data.frame(year = factor(rep(bg$year, 2)),
                  kind = rep(c("background only", "annotated"), each = nrow(bg)),
                  n = c(bg$background[, 1], bg$background[, 2] - bg$background[, 1]))
lab <- data.frame(year = factor(bg$year),
                  n = bg$background[, 2],
                  pct = sprintf("%.0f%%", 100 * bg$background[, 1] / bg$background[, 2]))
pc <- ggplot(bgd, aes(year, n, fill = kind)) +
  geom_col(width = .65) +
  geom_text(data = lab, aes(year, n, label = pct), inherit.aes = FALSE,
            vjust = -0.4, size = 3.1, colour = GREY) +
  scale_fill_manual(values = c("background only" = "#C9D2DD", "annotated" = COL_N)) +
  scale_y_continuous(expand = expansion(mult = c(0, .15))) +
  labs(title = "(c) Background-only versus annotated images", x = NULL, y = "images") +
  th + theme(legend.position = "top", legend.title = element_blank(),
             legend.text = element_text(size = 8))

pd <- ggplot(obj, aes(w_pct, h_pct, colour = cls)) +
  geom_abline(slope = 1, intercept = 0, linetype = "22", colour = GREY, linewidth = .4) +
  geom_point(alpha = .55, size = 1.2) +
  scale_colour_manual(values = c(MILCO = COL_M, NOMBO = COL_N)) +
  coord_equal() +
  labs(title = "(d) Bounding-box dimensions", x = "width (% of image)",
       y = "height (% of image)") +
  th + theme(panel.grid.major.x = element_line(colour = "grey92"),
             legend.position = "top", legend.title = element_blank(),
             legend.text = element_text(size = 8))

png("santos_eda_plots.png", width = 2400, height = 1800, res = 200)
grid::grid.newpage()
grid::pushViewport(grid::viewport(layout = grid::grid.layout(2, 2)))
vp <- function(r, c) grid::viewport(layout.pos.row = r, layout.pos.col = c)
print(pa, vp = vp(1, 1)); print(pb, vp = vp(1, 2))
print(pc, vp = vp(2, 1)); print(pd, vp = vp(2, 2))
dev.off()
cat("santos_eda_plots.png written\n")
