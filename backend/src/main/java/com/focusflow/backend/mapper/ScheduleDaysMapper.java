package com.focusflow.backend.mapper;

import java.time.DayOfWeek;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * Responsibility: Translates between API-friendly day arrays and database bitmasks. Architecture:
 * Mapper utility used by services/controllers when handling routines. Why: Keeps the compact DB
 * representation while offering a readable API contract.
 */
public final class ScheduleDaysMapper {

  private ScheduleDaysMapper() {}

  public static int toMask(List<DayOfWeek> days) {
    if (days == null || days.isEmpty()) {
      return 0;
    }
    int mask = 0;
    for (DayOfWeek day : days) {
      if (day == null) {
        continue;
      }
      // DayOfWeek is 1 (Monday) through 7 (Sunday); map to bit positions 0-6.
      mask |= 1 << (day.getValue() - 1);
    }
    return mask;
  }

  public static List<DayOfWeek> fromMask(int mask) {
    Set<DayOfWeek> days = EnumSet.noneOf(DayOfWeek.class);
    for (DayOfWeek day : DayOfWeek.values()) {
      int bit = 1 << (day.getValue() - 1);
      if ((mask & bit) == bit) {
        days.add(day);
      }
    }
    return new ArrayList<>(days);
  }
}
