/**
 * Deterministic, rule-based guidance for a measured 25-OH-D level.
 * Replaces the previous model-generated text — same output shape, no network.
 */

const FOODS = {
  Deficient: [
    { name: 'Wild Salmon & Mackerel', description: 'The richest natural source of Vitamin D3 — a 100 g serving covers most of a daily requirement.', category: 'Seafood' },
    { name: 'Cod Liver Oil', description: 'One teaspoon delivers a large D3 dose; useful while levels are being corrected.', category: 'Supplement Food' },
    { name: 'Fortified Milk & Cereals', description: 'Provides a steady daily intake of Vitamin D2/D3 alongside calcium.', category: 'Fortified Foods' },
    { name: 'Egg Yolks', description: 'Moderate Vitamin D, highest in eggs from pasture-raised hens.', category: 'Dairy & Eggs' },
  ],
  Insufficient: [
    { name: 'Fatty Fish', description: 'Salmon, sardines and mackerel twice a week lift levels reliably.', category: 'Seafood' },
    { name: 'UV-Exposed Mushrooms', description: 'Natural plant-based source of Vitamin D2 — good for vegetarian diets.', category: 'Vegetables' },
    { name: 'Fortified Milk & Cereals', description: 'A dependable daily top-up when sunlight exposure is limited.', category: 'Fortified Foods' },
    { name: 'Egg Yolks', description: 'Easy everyday addition that also supplies healthy fats for absorption.', category: 'Dairy & Eggs' },
  ],
  Sufficient: [
    { name: 'Oily Fish', description: 'Keep one or two portions a week to hold your level in the healthy range.', category: 'Seafood' },
    { name: 'Egg Yolks', description: 'A simple maintenance source of Vitamin D3.', category: 'Dairy & Eggs' },
    { name: 'UV-Exposed Mushrooms', description: 'Adds Vitamin D2 without changing your routine.', category: 'Vegetables' },
    { name: 'Fortified Yoghurt', description: 'Supports calcium absorption, which depends on adequate Vitamin D.', category: 'Fortified Foods' },
  ],
};

const TIPS = {
  Deficient: [
    'Levels are below 20 ng/mL — please consult a physician before starting high-dose supplementation.',
    'Aim for 20–30 minutes of midday sunlight on arms and legs, most days of the week.',
    'Take Vitamin D with a meal containing fat; absorption roughly doubles compared with an empty stomach.',
    'Retest in 8–12 weeks to confirm your level is recovering.',
  ],
  Insufficient: [
    'Aim for 15–20 minutes of daily sunlight exposure on uncovered skin.',
    'Pair Vitamin D rich foods with healthy fats such as olive oil, nuts or avocado for optimal absorption.',
    'Consider a Vitamin D3 supplement (1000–2000 IU daily) after checking with your doctor.',
    'Retest in 8–12 weeks to monitor progress.',
  ],
  Sufficient: [
    'Maintain your current sunlight and dietary habits — your level is in the healthy 30–100 ng/mL range.',
    'Outdoor activity supports both Vitamin D synthesis and bone loading.',
    'Avoid stacking multiple high-dose supplements; more is not better above 100 ng/mL.',
    'A check every 6–12 months is enough while levels stay in range.',
  ],
};

export function recommendationsForStatus(status) {
  return FOODS[status] || FOODS.Insufficient;
}

export function lifestyleTipsForStatus(status) {
  return TIPS[status] || TIPS.Insufficient;
}

export function statusDescription(level) {
  if (level < 20) return 'Your levels are critically low. Immediate supplementation recommended.';
  if (level < 30) return 'Below optimal range. Lifestyle changes and supplementation advised.';
  return 'Your Vitamin D levels are within the healthy clinical range of 30–100 ng/mL.';
}
