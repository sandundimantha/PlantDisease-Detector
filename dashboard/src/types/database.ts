export interface Profile {
  id: string;
  role: 'farmer' | 'officer' | 'admin';
  full_name: string;
  email?: string;
  phone?: string;
  district?: string;
  avatar_url?: string;
  farm_name?: string;
  farm_size?: string;
  primary_crops?: string[];
  preferred_lang?: string;
  bio?: string;
  is_banned?: boolean;
  created_at: string;
}

export interface Disease {
  id: string;
  name_en: string;
  name_si?: string;
  name_ta?: string;
  crop: string;
  model_label: string;
  description?: string;
  updated_at: string;
}

export interface Treatment {
  id: string;
  disease_id: string;
  kind: 'organic' | 'chemical' | 'cultural';
  steps_en?: string;
  steps_si?: string;
  steps_ta?: string;
  precautions?: string;
  est_cost_lkr?: number;
  sort_order: number;
  updated_at: string;
}

export interface CropCategory {
  id: string;
  name: string;
  name_si?: string;
  name_ta?: string;
  icon_url?: string;
  season?: string;
  is_active: boolean;
  sort_order: number;
  created_at: string;
}

export interface Announcement {
  id: string;
  title: string;
  body: string;
  image_url?: string;
  category: string;
  target_role: string;
  target_district?: string;
  is_published: boolean;
  published_at?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
}

export interface Consultation {
  id: string;
  farmer_id: string;
  officer_id?: string;
  disease_name?: string;
  severity?: string;
  status: 'pending' | 'open' | 'resolved';
  notes?: string;
  created_at: string;
  resolved_at?: string;
}

export interface Feedback {
  id: string;
  user_id?: string;
  type: string;
  subject?: string;
  message: string;
  status: string;
  priority: string;
  admin_notes?: string;
  created_at: string;
}

export interface Region {
  id: string;
  name: string;
  province: string;
  district?: string;
  area_km2?: number;
  officer_count: number;
  farmer_count: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface SystemSetting {
  key: string;
  value: string;
  label?: string;
  description?: string;
  data_type: 'string' | 'number' | 'boolean' | 'json';
  category: string;
  updated_by?: string;
  updated_at: string;
}
