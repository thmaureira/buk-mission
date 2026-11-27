module Ledger
  # Expires the remaining days of a lot. Idempotent per lot.
  class Expire
    def self.call(**) = new(**).call

    def initialize(grant:, reason: nil)
      @grant = grant
      @reason = reason
    end

    def call
      ActiveRecord::Base.transaction(requires_new: true) do
        @grant.lock!
        key = "expire:grant:#{@grant.id}"
        next if @grant.remaining_days.zero? || LedgerEntry.exists?(idempotency_key: key)

        entry = LedgerEntry.create!(
          leave_grant: @grant, kind: "expiration", days: -@grant.remaining_days,
          effective_on: @grant.expires_on, reason: @reason || default_reason,
          source: "job:expirations", idempotency_key: key
        )
        @grant.update!(remaining_days: 0)
        entry
      end
    end

    private

    def default_reason
      "Vencimiento #{@grant.leave_type.name} (#{@grant.leave_type.expiration_description.downcase})"
    end
  end
end
