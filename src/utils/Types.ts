// Types
export interface User {
  id: string;
  name: string;
  email: string;
  username: string;
}

export interface Message {
  id: string;
  text: string;
  isUser: boolean;
  timestamp: Date;
}

export interface Conversation {
  id: string;
  title: string;
  messages: Message[];
  lastMessage: Date;
}

export interface Patient {
  id: string;
  name: string;
  age: number;
  gender: string;
  consultations: Consultation[];
}

export interface Consultation {
  id: string;
  date: Date;
  diagnosis: string;
  temperature: number;
  bloodPressure: string;
  pulse: number;
  summary: string;
}