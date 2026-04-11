# frozen_string_literal: true

module Pricing
  # RF08: flags when the relevant unit price is unusually low vs peers (multi-store)
  # or vs recent history at a single qualifying store. Copy of unit logic stays here so
  # RF10 can extend ProductPricesSummary without conflicting in this file.
  class PriceOutlierAssessment
    # Relevant price is "atypical low" if below (1 - this) × reference median.
    RELATIVE_LOW_FRACTION = 0.30

    class << self
      def payload(by_store:, store_meets_threshold:, relevant_observation:)
        rel_u = relevant_observation && unit_price(relevant_observation)
        return default_payload if rel_u.blank? || !rel_u.positive?

        latest_by_store = latest_unit_by_disclosed_store(by_store, store_meets_threshold)
        values = latest_by_store.values.compact.select(&:positive?)

        atypical =
          if values.size >= 2
            ref = median(values)
            rel_u < ref * (1 - RELATIVE_LOW_FRACTION)
          elsif values.size == 1
            store_id = latest_by_store.keys.first
            atypical_vs_single_store_history?(by_store[store_id], rel_u)
          else
            false
          end

        if atypical
          {
            relevant_price_atypical_low: true,
            disclaimer: DISCLAIMER_PT
          }
        else
          default_payload
        end
      end

      private

      def default_payload
        { relevant_price_atypical_low: false, disclaimer: nil }
      end

      DISCLAIMER_PT =
        "Preço muito abaixo do usual nos dados recentes; pode ser promoção ou desconto pontual."

      def latest_unit_by_disclosed_store(by_store, store_meets_threshold)
        by_store.each_with_object({}) do |(store_id, rows), acc|
          next unless store_meets_threshold.call(rows)

          sorted = rows.sort_by { |o| [ o.observed_on, o.updated_at ] }.reverse
          u = unit_price(sorted.first)
          acc[store_id] = u
        end
      end

      def atypical_vs_single_store_history?(rows, rel_u)
        sorted = rows.sort_by { |o| [ o.observed_on, o.updated_at ] }.reverse
        units = sorted.first(3).filter_map { |o| unit_price(o) }
        units.select!(&:positive?)
        return false if units.size < 2

        ref = median(units)
        rel_u < ref * (1 - RELATIVE_LOW_FRACTION)
      end

      def median(values)
        s = values.sort
        n = s.size
        mid = n / 2
        if n.odd?
          s[mid]
        else
          (s[mid - 1] + s[mid]) / 2.to_d
        end
      end

      def unit_price(op)
        if op.valor_unitario.present? && op.valor_unitario.positive?
          return op.valor_unitario
        end
        if op.quantidade.present? && op.quantidade.positive? && op.valor_total.present?
          return op.valor_total / op.quantidade
        end

        op.valor_total if op.valor_total.present?
      end
    end
  end
end
