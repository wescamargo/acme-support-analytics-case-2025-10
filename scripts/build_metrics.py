#!/usr/bin/env python3
"""CLI to build CSV outputs for the Support case.
Usage:
  python scripts/build_metrics.py --tickets data/tickets_raw.csv --users data/users_raw.csv --out data/outputs
"""
import argparse, pandas as pd, numpy as np
from pathlib import Path

def to_datetime_safe(s):
  return pd.to_datetime(s, errors="coerce", utc=True)

def main():
  p = argparse.ArgumentParser()
  p.add_argument('--tickets', required=True)
  p.add_argument('--users', default=None)
  p.add_argument('--out', required=True)
  args = p.parse_args()

  out = Path(args.out); out.mkdir(parents=True, exist_ok=True)
  tickets = pd.read_csv(args.tickets)
  tickets['created_at'] = to_datetime_safe(tickets['created_at'])
  tickets['resolved_at'] = to_datetime_safe(tickets['resolved_at'])
  tickets['status'] = tickets['status'].astype(str).str.strip().str.lower()
  tickets['channel'] = tickets['channel'].astype(str).str.strip().str.lower()
  tickets['tag'] = tickets['tag'].astype(str).str.strip().str.lower().replace({'nan': np.nan})
  tickets['first_response_time'] = pd.to_numeric(tickets['first_response_time'], errors='coerce')
  tickets['created_day'] = tickets['created_at'].dt.floor('D')
  tickets['created_week'] = tickets['created_at'].dt.to_period('W').apply(lambda r: r.start_time)
  tickets['is_resolved'] = (tickets['status'].eq('resolved')) & tickets['resolved_at'].notna()
  tickets['resolution_time_minutes'] = np.where(
      tickets['is_resolved'],
      (tickets['resolved_at'] - tickets['created_at']).dt.total_seconds()/60.0,
      np.nan
  )

  # naive baseline classification for now
  def classify_baseline(text):
    if not isinstance(text, str): return 'others'
    t = text.lower()
    if any(k in t for k in ['checkout','cart','purchase','buy button','credit card','order page']): return 'checkout'
    if any(k in t for k in ['refund','chargeback','invoice','boleto','pix','billing','payment failed','payment error','payout','withdraw']): return 'financial'
    if any(k in t for k in ['engagement','reach','likes','comments','views','conversion','open rate','broadcast','notification','deliver','audience']): return 'engagement'
    return 'others'
  tickets['ai_category'] = tickets['message_text'].apply(classify_baseline)
  tickets['category_effective'] = tickets['tag'].fillna(tickets['ai_category'])

  daily_cat = tickets.groupby(['created_day','category_effective'], as_index=False)\
                     .agg(tickets_count=('ticket_id','nunique'))\
                     .rename(columns={'category_effective':'category'})
  daily_cat.to_csv(out / 'daily_tickets_by_category.csv', index=False)

  def pct95(x): 
    try: return np.nanpercentile(x, 95)
    except: return np.nan
  sla_daily = tickets.groupby('created_day', as_index=False).agg(
      avg_first_response=('first_response_time','mean'),
      median_first_response=('first_response_time','median'),
      p95_first_response=('first_response_time', pct95)
  )
  sla_daily.to_csv(out / 'sla_daily.csv', index=False)

  tickets['fcr_strict']  = ((tickets['is_resolved']) & (tickets['resolution_time_minutes'] <= 60)).astype(int)
  tickets['fcr_lenient'] = ((tickets['is_resolved']) & (tickets['resolution_time_minutes'] <= 240)).astype(int)
  fcr_daily = tickets.groupby('created_day', as_index=False).agg(
      resolved=('is_resolved','sum'),
      fcr_strict_sum=('fcr_strict','sum'),
      fcr_lenient_sum=('fcr_lenient','sum')
  )
  fcr_daily['fcr_strict_rate']  = np.where(fcr_daily['resolved']>0, fcr_daily['fcr_strict_sum']/fcr_daily['resolved'], np.nan)
  fcr_daily['fcr_lenient_rate'] = np.where(fcr_daily['resolved']>0, fcr_daily['fcr_lenient_sum']/fcr_daily['resolved'], np.nan)
  fcr_daily.to_csv(out / 'fcr_daily.csv', index=False)

  print('Done. Outputs written to', out)

if __name__ == '__main__':
  main()
