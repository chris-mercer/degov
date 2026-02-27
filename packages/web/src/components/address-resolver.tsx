import { useProfileQuery } from "@/hooks/useProfileQuery";
import { formatShortAddress } from "@/utils/address";

import type { Address } from "viem";

interface AddressResolverProps {
  address: Address;
  showShortAddress?: boolean;
  skipFetch?: boolean;
  children: (value: string) => React.ReactNode;
}

export function AddressResolver({
  address,
  showShortAddress = false,
  skipFetch = false,
  children,
}: AddressResolverProps) {
  const { data: profileData } = useProfileQuery(address, { skip: skipFetch });

  const profileName = profileData?.data?.name;

  const displayValue =
    profileName ||
    (showShortAddress ? formatShortAddress(address) : address);

  return <>{children(displayValue)}</>;
}
