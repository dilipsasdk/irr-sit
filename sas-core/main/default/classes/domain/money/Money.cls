/**
 * Generic representation of money.
 *
 * Instances of this class represent a specific sum of money in a specific currency.
 */
public without sharing class Money implements Comparable {
  public Decimal amount { get; private set; }
  public CurrencyCode currencyCode { get; private set; }

  public class MismatchedCurrenciesException extends Exception {
  }

  public enum CurrencyCode {
    AUD,
    AED,
    CAD,
    CHF,
    CNY,
    CZK,
    DKK,
    EUR,
    GBP,
    HKD,
    JPY,
    NOK,
    NZD,
    PLN,
    SEK,
    SGD,
    THB,
    USD
  }

  public static final Map<CurrencyCode, String> CURRENCY_ENUM_TO_PICKLIST_VALUE = new Map<CurrencyCode, String>{
    CurrencyCode.AUD => 'AUD',
    CurrencyCode.AED => 'AED',
    CurrencyCode.CAD => 'CAD',
    CurrencyCode.CHF => 'CHF',
    CurrencyCode.CNY => 'CNY',
    CurrencyCode.CZK => 'CZK',
    CurrencyCode.DKK => 'DKK',
    CurrencyCode.EUR => 'EUR',
    CurrencyCode.GBP => 'GBP',
    CurrencyCode.HKD => 'HKD',
    CurrencyCode.JPY => 'JPY',
    CurrencyCode.NOK => 'NOK',
    CurrencyCode.NZD => 'NZD',
    CurrencyCode.PLN => 'PLN',
    CurrencyCode.SEK => 'SEK',
    CurrencyCode.SGD => 'SGD',
    CurrencyCode.THB => 'THB',
    CurrencyCode.USD => 'USD'
  };

  public static final Map<String, CurrencyCode> CURRENCY_PICKLIST_VALUE_TO_ENUM = new Map<String, CurrencyCode>{
    'AUD' => CurrencyCode.AUD,
    'AED' => CurrencyCode.AED,
    'CAD' => CurrencyCode.CAD,
    'CHF' => CurrencyCode.CHF,
    'CNY' => CurrencyCode.CNY,
    'CZK' => CurrencyCode.CZK,
    'DKK' => CurrencyCode.DKK,
    'EUR' => CurrencyCode.EUR,
    'GBP' => CurrencyCode.GBP,
    'HKD' => CurrencyCode.HKD,
    'JPY' => CurrencyCode.JPY,
    'NOK' => CurrencyCode.NOK,
    'NZD' => CurrencyCode.NZD,
    'PLN' => CurrencyCode.PLN,
    'SEK' => CurrencyCode.SEK,
    'SGD' => CurrencyCode.SGD,
    'THB' => CurrencyCode.THB,
    'USD' => CurrencyCode.USD
  };

  public Money(Decimal amount, CurrencyCode currencyCode) {
    U.verifyNotNull(new List<Object>{ amount, currencyCode });

    this.amount = amount;
    this.currencyCode = currencyCode;
  }

  public Money add(Money that) {
    U.verifyNotNull(that);
    verifySameCurrency(that);

    return new Money(this.amount + that.amount, this.currencyCode);
  }

  public Money substract(Money that) {
    U.verifyNotNull(that);
    verifySameCurrency(that);

    return new Money(this.amount - that.amount, this.currencyCode);
  }

  public Money divideBy(Decimal divisor) {
    U.verifyNotNull(divisor);
    return new Money(this.amount / divisor, this.currencyCode);
  }

  public Money multiplyBy(Decimal multiplier) {
    U.verifyNotNull(multiplier);
    return new Money(this.amount * multiplier, this.currencyCode);
  }

  public Money convertTo(CurrencyCode toCurrency, ExchangeRate withRate) {
    U.verifyNotNull(new List<Object>{ toCurrency, withRate });
    if (
      withRate.fromCurrency != this.currencyCode ||
      withRate.toCurrency != toCurrency
    ) {
      throw new MismatchedCurrenciesException('Currencies do not match.');
    }
    if (toCurrency == this.currencyCode) {
      return new Money(this.amount, toCurrency);
    }
    return new Money(this.amount * withRate.rate, toCurrency);
  }

  public Integer inEuroBonusPoints() {
    if (this.CurrencyCode != Money.CurrencyCode.EUR) {
      throw new MismatchedCurrenciesException(
        'Only euros can be converted to EuroBonus points.'
      );
    }

    return Math.floor(
        this.amount * Settlements.CONVERSION_RATE_EUR_TO_EB_POINTS
      )
      .intValue();
  }

  public Money setScale(Integer to) {
    Decimal newAmount = this.amount;
    newAmount = newAmount.setScale(to);

    return new Money(newAmount, this.currencyCode);
  }

  public Boolean greaterThan(Money that) {
    verifySameCurrency(that);
    return this.amount > that.amount;
  }

  public Boolean lessThan(Money that) {
    verifySameCurrency(that);
    return this.amount > that.amount;
  }

  public Boolean equals(Object obj) {
    if (obj instanceof Money) {
      Money that = (Money) obj;

      return this.currencyCode == that.currencyCode &&
        this.amount == that.amount;
    } else {
      return false;
    }
  }

  public Integer compareTo(Object compareTo) {
    if (!(compareTo instanceof Money)) {
      throw new System.TypeException('Cannot compare money to other objects.');
    }

    Money that = (Money) compareTo;
    verifySameCurrency(that);

    if (this.amount == that.amount) {
      return 0;
    } else {
      return this.amount > that.amount ? 1 : -1;
    }
  }

  public Integer hashCode() {
    return 31 * this.amount.intValue() * currencyCode.hashCode();
  }

  public override String toString() {
    return this.amount.toPlainString() + ' ' + this.currencyCode.name();
  }

  private void verifySameCurrency(Money that) {
    if (this.currencyCode != that.currencyCode) {
      throw new MismatchedCurrenciesException(
        'Cannot compare money instances of different currencies'
      );
    }
  }
}
