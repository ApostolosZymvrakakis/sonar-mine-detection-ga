import sys
import pandas as pd
import numpy as np
from scipy import stats

CSV = sys.argv[1] if len(sys.argv) > 1 else 'cv_results.csv'
df = pd.read_csv(CSV)

base = df[df.config == 'baseline'].set_index('fold').sort_index()
ga   = df[df.config == 'ga'      ].set_index('fold').sort_index()
assert (base.index == ga.index).all(), 'folds do not correspond -- pairing broken'
n = len(base)

print(f'TABLE 4.2  --  {n}-fold stratified group-aware cross-validation\n')
print(f'{"Metric":<12}{"Baseline":>18}{"GA-optimised":>18}{"Folds won by GA":>20}')
for col, name in (('mAP50','mAP@0.5'), ('recall','Recall'),
                  ('precision','Precision'), ('f1','F1')):
    b, g = base[col].values, ga[col].values
    wins = int((g > b).sum())
    print(f'{name:<12}{b.mean():>10.3f} ± {b.std(ddof=1):<5.3f}'
          f'{g.mean():>10.3f} ± {g.std(ddof=1):<5.3f}'
          f'{wins:>14d}/{n} ({100*wins/n:.1f}%)')

d = ga['mAP50'].values - base['mAP50'].values
wins = int((d > 0).sum())

sign_two = stats.binomtest(wins, n, 0.5, alternative='two-sided').pvalue
sign_one = stats.binomtest(wins, n, 0.5, alternative='greater').pvalue
w_stat, w_p = stats.wilcoxon(d, alternative='two-sided')
t_stat, t_p = stats.ttest_rel(ga['mAP50'], base['mAP50'])
cohen_d = d.mean() / d.std(ddof=1)

print(f'\n\nTABLE 4.3  --  paired difference in mAP@0.5 (GA - baseline), n = {n}\n')
print(f'  Mean paired difference   {d.mean():+.3f} ± {d.std(ddof=1):.3f}')
print(f'  Range of differences     {d.min():+.3f} to {d.max():+.3f}')
print(f'  Sign test (two-sided)    {wins}/{n}, p = {sign_two:.2g}')
print(f'    (one-sided variant)    p = {sign_one:.2g}')
print(f'  Wilcoxon signed-rank     W = {w_stat:.1f}, p = {w_p:.2g}')
print(f"  Paired t-test            t({n-1}) = {t_stat:.2f}, p = {t_p:.2g}")
print(f"  Cohen's d                {cohen_d:.2f}")

lost = np.where(d < 0)[0]
print(f'\n\nFolds won by the baseline ({len(lost)})\n')
print(f'{"Fold":<8}{"Baseline":>10}{"GA":>10}{"Margin":>10}{"Baseline rank":>16}')
rank = base['mAP50'].rank(method='min').astype(int)
for i in lost:
    f = base.index[i]
    print(f'{f:<8}{base["mAP50"].iloc[i]:>10.3f}{ga["mAP50"].iloc[i]:>10.3f}'
          f'{base["mAP50"].iloc[i]-ga["mAP50"].iloc[i]:>10.3f}{rank.iloc[i]:>12d}/{n}')
print(f'\n  Mean baseline score on those folds: {base["mAP50"].iloc[lost].mean():.3f}'
      f'   (overall baseline mean {base["mAP50"].mean():.3f})')

ok = (base.mAP50_95 > 0) & (ga.mAP50_95 > 0)
if ok.any():
    print(f'\n\nmAP@0.5:0.95, the {int(ok.sum())} folds for which it survived transcription\n')
    print(f'  baseline {base.mAP50_95[ok].mean():.3f}   '
          f'GA {ga.mAP50_95[ok].mean():.3f}   '
          f'GA ahead on {int((ga.mAP50_95[ok] > base.mAP50_95[ok]).sum())}/{int(ok.sum())}')
