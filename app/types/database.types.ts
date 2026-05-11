export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export interface Database {
  public: {
    Tables: {
      admin_emails: {
        Row: {
          email: string
          created_at: string
        }
        Insert: {
          email: string
          created_at?: string
        }
        Update: {
          email?: string
          created_at?: string
        }
        Relationships: []
      }
      players: {
        Row: {
          id: string
          name: string
          rating: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          rating: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          rating?: number
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      tournaments: {
        Row: {
          id: string
          event_date: string
          winner_player_id: string
          loser_player_id: string
          winner_rating_before: number
          winner_rating_after: number
          loser_rating_before: number
          loser_rating_after: number
          created_by: string
          created_at: string
        }
        Insert: {
          id?: string
          event_date: string
          winner_player_id: string
          loser_player_id: string
          winner_rating_before: number
          winner_rating_after: number
          loser_rating_before: number
          loser_rating_after: number
          created_by: string
          created_at?: string
        }
        Update: {
          id?: string
          event_date?: string
          winner_player_id?: string
          loser_player_id?: string
          winner_rating_before?: number
          winner_rating_after?: number
          loser_rating_before?: number
          loser_rating_after?: number
          created_by?: string
          created_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      is_admin: {
        Args: Record<PropertyKey, never>
        Returns: boolean
      }
      delete_tournament_result: {
        Args: {
          p_tournament_id: string
        }
        Returns: Database['public']['Tables']['tournaments']['Row']
      }
      record_tournament_result: {
        Args: {
          p_event_date: string
          p_winner_player_id: string
          p_loser_player_id: string
        }
        Returns: Database['public']['Tables']['tournaments']['Row']
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}
