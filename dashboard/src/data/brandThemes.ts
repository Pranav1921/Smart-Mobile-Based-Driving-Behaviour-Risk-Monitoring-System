export interface EnterpriseBrand {
  id: string;
  name: string;
  tagline: string;
  logoText: string;
  primaryColor: string;
  secondaryColor: string;
  darkBg: string;
  surfaceColor: string;
  textPrimary: string;
  textSecondary: string;
  badgeTone: 'orange' | 'red' | 'blue' | 'yellow' | 'emerald';
  sdkName: string;
}

// Unified Tactical Theme for the entire Intelligence Network
export const UNIFIED_THEME: EnterpriseBrand = {
  id: 'smartdrive_unified',
  name: 'Smart Driving Risk Intelligence',
  tagline: 'Autonomous Driving Behaviour & Risk Monitoring System',
  logoText: 'SmartDrive',
  primaryColor: '#1B3B2B',
  secondaryColor: '#10B981',
  darkBg: '#F5F0E8',
  surfaceColor: '#FFFFFF',
  textPrimary: '#1B3B2B',
  textSecondary: '#64748B',
  badgeTone: 'emerald',
  sdkName: 'SmartDrive Telemetry Engine v4.2',
};

export function getActiveBrand(): EnterpriseBrand {
  return UNIFIED_THEME;
}

export function setActiveBrand(_: string): EnterpriseBrand {
  return UNIFIED_THEME;
}
