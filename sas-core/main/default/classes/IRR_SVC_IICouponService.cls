public interface IRR_SVC_IICouponService {
    List<IRR_MOD_ICouponInfo> createFlightIrregularity(IRR_MOD_DelayInfo delayInfo,Map<String ,List<String>> classWithPassenger);
  }