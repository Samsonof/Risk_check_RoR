class RiskCaseStore
  CASES = [
    {
      id: "C-10482",
      name: "Ivan Petrov",
      country: "Poland",
      registration_ip: "91.204.18.44",
      registration_city: "Warsaw",
      registration_country: "Poland",
      phone_country: "Poland",
      bank_country: "Lithuania",
      email: "ivan.petrov@example.com",
      request_id: "W-7781",
      withdrawal_amount: 14_200,
      currency: "USD",
      withdrawal_method: "USDT TRC20",
      withdrawal_destination: "Wallet 0x7a...19b",
      withdrawal_geo: "Berlin, Germany",
      trades_count: 3,
      trades_volume: 18_400,
      active_days: 1,
      kyc_level_2: false,
      deposits_before_kyc_l1: true,
      kyc_l1_hours_before_withdrawal: 32,
      days_after_first_deposit: 5,
      payment_attempts_pattern: {
        en: "Same value repeated, then crypto top-up",
        es: "Mismo importe repetido, luego recarga cripto",
        ru: "Одинаковая сумма повторялась, затем пополнение криптой"
      },
      intercom_alert: {
        en: "High-risk withdrawal. Shared wallet and deposits before KYC L1. Support should avoid payment details in chat.",
        es: "Retiro de alto riesgo. Wallet compartida y depositos antes de KYC L1. Soporte no debe discutir detalles de pago.",
        ru: "Вывод с высоким риском. Общий кошелек и депозиты до KYC L1. Саппорту не раскрывать платежные детали в чате."
      },
      deposit_methods: [
        { label: "Visa 4899 **** 4412", count: 2, amount: 10_400, note: "shared card" },
        { label: "USDT TRC20", count: 1, amount: 8_200, note: "new wallet" }
      ],
      month_history: [
        ["2026-05-11", "Deposit", "Visa 4899 **** 4412", "USD 5,200", "before KYC L1"],
        ["2026-05-12", "Deposit", "Visa 4899 **** 4412", "USD 5,200", "before KYC L1"],
        ["2026-05-14", "Deposit", "USDT TRC20", "USD 8,200", "new wallet"],
        ["2026-05-16", "Withdrawal", "USDT TRC20", "USD 14,200", "manual review"]
      ],
      triggers: ["shared_crypto_wallet", "deposit_before_kyc", "recent_kyc", "first_deposit_less_than_week", "no_trading"],
      locks: ["withdrawal", "deposits", "open_trades"],
      approvals: [
        { role: "Risk analyst", person: "Marta Kowalska", status: "approved", required: true },
        { role: "Compliance lead", person: "Omar Haddad", status: "pending", required: true },
        { role: "Payments manager", person: "Lucia Romero", status: "pending", required: true },
        { role: "Superadmin", person: "Anya Morozova", status: "override_available", required: false }
      ]
    },
    {
      id: "C-10508",
      name: "Elena Garcia",
      country: "Spain",
      registration_ip: "83.48.120.8",
      registration_city: "Madrid",
      registration_country: "Spain",
      phone_country: "Spain",
      bank_country: "Spain",
      email: "elena.garcia@example.es",
      request_id: "W-7790",
      withdrawal_amount: 5_200,
      currency: "EUR",
      withdrawal_method: "Visa OCT",
      withdrawal_destination: "Visa 4147 **** 8011",
      withdrawal_geo: "Madrid, Spain",
      trades_count: 9,
      trades_volume: 42_800,
      active_days: 3,
      kyc_level_2: true,
      deposits_before_kyc_l1: false,
      kyc_l1_hours_before_withdrawal: 146,
      days_after_first_deposit: 6,
      payment_attempts_pattern: {
        en: "Failed deposits decreased: 5000 -> 3000 -> 1000",
        es: "Depositos fallidos bajan: 5000 -> 3000 -> 1000",
        ru: "Неудачные депозиты уменьшались: 5000 -> 3000 -> 1000"
      },
      intercom_alert: {
        en: "Medium-risk withdrawal. Same bank, multiple cards and decreasing failed deposits. Ask for clean source-of-funds explanation.",
        es: "Retiro de riesgo medio. Mismo banco, varias tarjetas y depositos fallidos descendentes. Pedir explicacion de origen de fondos.",
        ru: "Вывод со средним риском. Один банк, несколько карт и убывающие неудачные депозиты. Запросить источник средств."
      },
      deposit_methods: [
        { label: "Santander Visa 4147 **** 8011", count: 2, amount: 4_200, note: "same bank" },
        { label: "Santander Mastercard 5355 **** 2040", count: 1, amount: 2_400, note: "same bank" },
        { label: "Failed attempts", count: 3, amount: 0, note: "5000 -> 3000 -> 1000" }
      ],
      month_history: [
        ["2026-05-10", "Failed deposit", "Santander Visa", "EUR 5,000", "declined"],
        ["2026-05-10", "Failed deposit", "Santander Visa", "EUR 3,000", "declined"],
        ["2026-05-10", "Failed deposit", "Santander Visa", "EUR 1,000", "declined"],
        ["2026-05-16", "Withdrawal", "Visa OCT", "EUR 5,200", "manual review"]
      ],
      triggers: ["two_cards_same_bank", "failed_payments_descending", "first_deposit_less_than_week"],
      locks: ["withdrawal"],
      approvals: [
        { role: "Risk analyst", person: "Marta Kowalska", status: "approved", required: true },
        { role: "Compliance lead", person: "Omar Haddad", status: "approved", required: true },
        { role: "Payments manager", person: "Lucia Romero", status: "pending", required: true },
        { role: "Superadmin", person: "Anya Morozova", status: "override_available", required: false }
      ]
    },
    {
      id: "C-10512",
      name: "Diego Ruiz",
      country: "Mexico",
      registration_ip: "189.203.44.13",
      registration_city: "Mexico City",
      registration_country: "Mexico",
      phone_country: "Mexico",
      bank_country: "Colombia",
      email: "diego.ruiz@example.mx",
      request_id: "W-7794",
      withdrawal_amount: 6_800,
      currency: "USD",
      withdrawal_method: "USDT ERC20",
      withdrawal_destination: "Wallet 0xb4...e91",
      withdrawal_geo: "Bogota, Colombia",
      trades_count: 17,
      trades_volume: 76_800,
      active_days: 5,
      kyc_level_2: false,
      deposits_before_kyc_l1: false,
      kyc_l1_hours_before_withdrawal: 190,
      days_after_first_deposit: 10,
      payment_attempts_pattern: {
        en: "Card country differs from registration country",
        es: "Pais de tarjeta distinto del pais de registro",
        ru: "Страна карты отличается от страны регистрации"
      },
      intercom_alert: {
        en: "High-risk withdrawal. Foreign BIN and wallet already connected to another profile.",
        es: "Retiro de alto riesgo. BIN extranjero y wallet ya conectada a otro perfil.",
        ru: "Вывод с высоким риском. Иностранный BIN и кошелек уже связан с другим профилем."
      },
      deposit_methods: [
        { label: "Visa 4777 **** 0921", count: 3, amount: 9_200, note: "BIN Colombia" }
      ],
      month_history: [
        ["2026-05-06", "Deposit", "Visa 4777 **** 0921", "USD 3,200", "foreign BIN"],
        ["2026-05-08", "Deposit", "Visa 4777 **** 0921", "USD 2,500", "foreign BIN"],
        ["2026-05-16", "Withdrawal", "USDT ERC20", "USD 6,800", "shared wallet"]
      ],
      triggers: ["foreign_card_country", "shared_crypto_wallet", "withdrawal_geo_mismatch"],
      locks: ["withdrawal", "deposits"],
      approvals: [
        { role: "Risk analyst", person: "Marta Kowalska", status: "pending", required: true },
        { role: "Compliance lead", person: "Omar Haddad", status: "pending", required: true },
        { role: "Payments manager", person: "Lucia Romero", status: "pending", required: true },
        { role: "Superadmin", person: "Anya Morozova", status: "override_available", required: false }
      ]
    },
    {
      id: "C-10519",
      name: "Maya Thompson",
      country: "United Kingdom",
      registration_ip: "82.132.214.91",
      registration_city: "London",
      registration_country: "United Kingdom",
      phone_country: "United Kingdom",
      bank_country: "United Kingdom",
      email: "maya.thompson@example.co.uk",
      request_id: "W-7801",
      withdrawal_amount: 1_850,
      currency: "GBP",
      withdrawal_method: "Bank transfer",
      withdrawal_destination: "Barclays **** 7710",
      withdrawal_geo: "London, United Kingdom",
      trades_count: 43,
      trades_volume: 124_600,
      active_days: 14,
      kyc_level_2: true,
      deposits_before_kyc_l1: false,
      kyc_l1_hours_before_withdrawal: 290,
      days_after_first_deposit: 18,
      payment_attempts_pattern: {
        en: "Stable deposits from one verified bank account",
        es: "Depositos estables desde una cuenta bancaria verificada",
        ru: "Стабильные депозиты с одного подтвержденного банковского счета"
      },
      intercom_alert: {
        en: "Low-risk request. Support can treat this as standard, with no fraud warning visible to the client.",
        es: "Solicitud de bajo riesgo. Soporte puede tratarla como estandar, sin alerta de fraude visible para el cliente.",
        ru: "Заявка с низким риском. Саппорт может вести как стандартную, без видимого клиенту fraud-предупреждения."
      },
      deposit_methods: [
        { label: "Barclays debit **** 7710", count: 4, amount: 5_600, note: "verified owner" },
        { label: "Bank transfer", count: 1, amount: 1_500, note: "same country" }
      ],
      month_history: [
        ["2026-04-28", "Deposit", "Barclays debit", "GBP 1,400", "settled"],
        ["2026-05-03", "Deposit", "Bank transfer", "GBP 1,500", "settled"],
        ["2026-05-11", "Deposit", "Barclays debit", "GBP 1,200", "settled"],
        ["2026-05-16", "Withdrawal", "Bank transfer", "GBP 1,850", "ready for release"]
      ],
      triggers: ["manual_review_volume"],
      locks: [],
      approvals: [
        { role: "Risk analyst", person: "Marta Kowalska", status: "approved", required: true },
        { role: "Compliance lead", person: "Omar Haddad", status: "not_required", required: false },
        { role: "Payments manager", person: "Lucia Romero", status: "approved", required: true },
        { role: "Superadmin", person: "Anya Morozova", status: "override_available", required: false }
      ]
    },
    {
      id: "C-10527",
      name: "Sofia Almeida",
      country: "Brazil",
      registration_ip: "177.45.88.10",
      registration_city: "Sao Paulo",
      registration_country: "Brazil",
      phone_country: "Portugal",
      bank_country: "Brazil",
      email: "sofia.almeida@example.br",
      request_id: "W-7812",
      withdrawal_amount: 9_700,
      currency: "USD",
      withdrawal_method: "USDT TRC20",
      withdrawal_destination: "Wallet 0xd1...8fa",
      withdrawal_geo: "Lisbon, Portugal",
      trades_count: 0,
      trades_volume: 0,
      active_days: 0,
      kyc_level_2: false,
      deposits_before_kyc_l1: true,
      kyc_l1_hours_before_withdrawal: 18,
      days_after_first_deposit: 2,
      payment_attempts_pattern: {
        en: "Three accounts registered from the same IP, then crypto withdrawal",
        es: "Tres cuentas registradas desde la misma IP, luego retiro cripto",
        ru: "Три аккаунта с одного IP, затем вывод в крипту"
      },
      intercom_alert: {
        en: "Critical fraud risk. Same registration IP cluster, no trading and recent KYC. Keep withdrawal blocked until Compliance clears.",
        es: "Riesgo critico. Cluster por misma IP, sin trading y KYC reciente. Mantener retiro bloqueado hasta Compliance.",
        ru: "Критический риск. Кластер с одного IP, нет торговли и свежий KYC. Держать вывод заблокированным до Compliance."
      },
      deposit_methods: [
        { label: "Pix transfer", count: 1, amount: 4_800, note: "before KYC L1" },
        { label: "USDT TRC20", count: 1, amount: 6_100, note: "new wallet" }
      ],
      month_history: [
        ["2026-05-14", "Deposit", "Pix transfer", "USD 4,800", "before KYC L1"],
        ["2026-05-15", "Deposit", "USDT TRC20", "USD 6,100", "new wallet"],
        ["2026-05-16", "Withdrawal", "USDT TRC20", "USD 9,700", "blocked by IP cluster"]
      ],
      triggers: ["multi_ip_registration", "deposit_before_kyc", "recent_kyc", "first_deposit_less_than_week", "no_trading", "withdrawal_geo_mismatch"],
      locks: ["withdrawal", "deposits", "open_trades"],
      approvals: [
        { role: "Risk analyst", person: "Marta Kowalska", status: "pending", required: true },
        { role: "Compliance lead", person: "Omar Haddad", status: "pending", required: true },
        { role: "Payments manager", person: "Lucia Romero", status: "pending", required: true },
        { role: "Superadmin", person: "Anya Morozova", status: "override_available", required: false }
      ]
    },
    {
      id: "C-10534",
      name: "Noah Stein",
      country: "Germany",
      registration_ip: "95.91.44.202",
      registration_city: "Berlin",
      registration_country: "Germany",
      phone_country: "Germany",
      bank_country: "Netherlands",
      email: "noah.stein@example.de",
      request_id: "W-7819",
      withdrawal_amount: 3_450,
      currency: "EUR",
      withdrawal_method: "SEPA",
      withdrawal_destination: "NL IBAN **** 4901",
      withdrawal_geo: "Berlin, Germany",
      trades_count: 6,
      trades_volume: 11_900,
      active_days: 2,
      kyc_level_2: true,
      deposits_before_kyc_l1: false,
      kyc_l1_hours_before_withdrawal: 86,
      days_after_first_deposit: 11,
      payment_attempts_pattern: {
        en: "One bank card appears on two accounts with different names",
        es: "Una tarjeta bancaria aparece en dos cuentas con nombres distintos",
        ru: "Одна банковская карта встречается в двух аккаунтах с разными именами"
      },
      intercom_alert: {
        en: "Card ownership risk. Support should ask for payment method verification and avoid confirming linked-account details.",
        es: "Riesgo de titularidad de tarjeta. Pedir verificacion del metodo de pago sin revelar cuentas vinculadas.",
        ru: "Риск владения картой. Саппорт запрашивает проверку метода оплаты, не раскрывая связанные аккаунты."
      },
      deposit_methods: [
        { label: "ING Visa 4485 **** 4901", count: 2, amount: 3_600, note: "seen on another account" },
        { label: "SEPA transfer", count: 1, amount: 1_200, note: "same IBAN family" }
      ],
      month_history: [
        ["2026-05-05", "Deposit", "ING Visa 4485 **** 4901", "EUR 1,800", "shared instrument"],
        ["2026-05-09", "Deposit", "ING Visa 4485 **** 4901", "EUR 1,800", "shared instrument"],
        ["2026-05-16", "Withdrawal", "SEPA", "EUR 3,450", "ownership review"]
      ],
      triggers: ["shared_bank_card", "foreign_card_country", "manual_review_volume"],
      locks: ["withdrawal"],
      approvals: [
        { role: "Risk analyst", person: "Marta Kowalska", status: "approved", required: true },
        { role: "Compliance lead", person: "Omar Haddad", status: "pending", required: true },
        { role: "Payments manager", person: "Lucia Romero", status: "pending", required: true },
        { role: "Superadmin", person: "Anya Morozova", status: "override_available", required: false }
      ]
    },
    {
      id: "C-10541",
      name: "Aisha Khan",
      country: "United Arab Emirates",
      registration_ip: "5.32.61.14",
      registration_city: "Dubai",
      registration_country: "United Arab Emirates",
      phone_country: "United Arab Emirates",
      bank_country: "United Arab Emirates",
      email: "aisha.khan@example.ae",
      request_id: "W-7826",
      withdrawal_amount: 22_500,
      currency: "USD",
      withdrawal_method: "Wire transfer",
      withdrawal_destination: "Emirates NBD **** 1204",
      withdrawal_geo: "Dubai, United Arab Emirates",
      trades_count: 31,
      trades_volume: 198_400,
      active_days: 9,
      kyc_level_2: true,
      deposits_before_kyc_l1: false,
      kyc_l1_hours_before_withdrawal: 260,
      days_after_first_deposit: 21,
      payment_attempts_pattern: {
        en: "Email changed 4 hours before a high-value withdrawal",
        es: "Email cambiado 4 horas antes de un retiro de alto valor",
        ru: "Email изменен за 4 часа до крупного вывода"
      },
      intercom_alert: {
        en: "Security-change hold. Confirm account takeover checks before releasing the wire.",
        es: "Hold por cambio de seguridad. Confirmar chequeos de account takeover antes de liberar la transferencia.",
        ru: "Hold из-за изменения безопасности. Проверить account takeover перед выпуском банковского вывода."
      },
      deposit_methods: [
        { label: "Wire transfer", count: 2, amount: 28_000, note: "verified bank" },
        { label: "Visa 4571 **** 1204", count: 1, amount: 4_500, note: "same country" }
      ],
      month_history: [
        ["2026-04-27", "Deposit", "Wire transfer", "USD 18,000", "settled"],
        ["2026-05-07", "Deposit", "Visa 4571 **** 1204", "USD 4,500", "settled"],
        ["2026-05-16", "Profile change", "Email", "0", "recent security change"],
        ["2026-05-16", "Withdrawal", "Wire transfer", "USD 22,500", "security hold"]
      ],
      triggers: ["recent_email_change", "manual_review_volume"],
      locks: ["withdrawal", "open_trades"],
      approvals: [
        { role: "Risk analyst", person: "Marta Kowalska", status: "approved", required: true },
        { role: "Compliance lead", person: "Omar Haddad", status: "approved", required: true },
        { role: "Payments manager", person: "Lucia Romero", status: "pending", required: true },
        { role: "Superadmin", person: "Anya Morozova", status: "override_available", required: false }
      ]
    },
    {
      id: "C-10549",
      name: "Luis Martinez",
      country: "Argentina",
      registration_ip: "190.210.33.88",
      registration_city: "Buenos Aires",
      registration_country: "Argentina",
      phone_country: "Chile",
      bank_country: "Chile",
      email: "luis.martinez@example.ar",
      request_id: "W-7833",
      withdrawal_amount: 7_300,
      currency: "USD",
      withdrawal_method: "USDT ERC20",
      withdrawal_destination: "Wallet 0xc9...0de",
      withdrawal_geo: "Santiago, Chile",
      trades_count: 4,
      trades_volume: 9_700,
      active_days: 1,
      kyc_level_2: false,
      deposits_before_kyc_l1: false,
      kyc_l1_hours_before_withdrawal: 54,
      days_after_first_deposit: 4,
      payment_attempts_pattern: {
        en: "2FA changed, then withdrawal to a wallet already seen on another profile",
        es: "2FA cambiado, luego retiro a wallet vista en otro perfil",
        ru: "2FA изменен, затем вывод на кошелек, который уже был у другого профиля"
      },
      intercom_alert: {
        en: "High-risk crypto withdrawal. Country mismatch, recent 2FA change and reused wallet.",
        es: "Retiro cripto de alto riesgo. Pais no coincide, 2FA reciente y wallet reutilizada.",
        ru: "Высокий риск криптовывода. Несовпадение стран, свежая смена 2FA и повторный кошелек."
      },
      deposit_methods: [
        { label: "Banco de Chile Visa **** 7712", count: 2, amount: 6_500, note: "foreign BIN" },
        { label: "Failed attempts", count: 3, amount: 0, note: "9000 -> 5000 -> 2500" }
      ],
      month_history: [
        ["2026-05-12", "Failed deposit", "Banco de Chile Visa", "USD 9,000", "declined"],
        ["2026-05-12", "Failed deposit", "Banco de Chile Visa", "USD 5,000", "declined"],
        ["2026-05-13", "Deposit", "Banco de Chile Visa", "USD 6,500", "foreign BIN"],
        ["2026-05-16", "Security change", "2FA", "0", "recent change"],
        ["2026-05-16", "Withdrawal", "USDT ERC20", "USD 7,300", "crypto hold"]
      ],
      triggers: ["recent_2fa_change", "phone_bank_country_mismatch", "foreign_card_country", "failed_payments_descending", "shared_crypto_wallet", "first_deposit_less_than_week"],
      locks: ["withdrawal", "deposits", "open_trades"],
      approvals: [
        { role: "Risk analyst", person: "Marta Kowalska", status: "pending", required: true },
        { role: "Compliance lead", person: "Omar Haddad", status: "pending", required: true },
        { role: "Payments manager", person: "Lucia Romero", status: "pending", required: true },
        { role: "Superadmin", person: "Anya Morozova", status: "override_available", required: false }
      ]
    }
  ].freeze

  def self.all
    CASES
  end

  def self.find(id)
    CASES.find { |risk_case| risk_case[:id] == id }
  end

  def self.localized(value)
    return value unless value.is_a?(Hash)

    value[I18n.locale] || value[:en] || value.values.first
  end
end
