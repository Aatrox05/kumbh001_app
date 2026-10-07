const OpenAI = require('openai');
const db = require('../config/database');

class AIService {
  constructor() {
    this.apiKey = process.env.AI_API_KEY;
    this.openai = this.apiKey ? new OpenAI({ apiKey: this.apiKey }) : null;
  }

  healthCheck() {
    return {
      status: this.openai ? 'configured' : 'missing_credentials',
      provider: 'openai'
    };
  }

  async getContextData(type = 'GENERAL') {
    try {
      let contextStr = "VERIFIED KUMBH MELA INFORMATION:\n\n";

      if (type === 'GENERAL' || type === 'TRIP') {
        const places = await db.query("SELECT * FROM places WHERE is_verified = 1 LIMIT 50");
        contextStr += "PLACES & ATTRACTIONS:\n";
        places.forEach(p => {
          contextStr += `- ${p.name} (${p.category}): ${p.description}. Crowd Level: ${p.crowd_level}\n`;
        });
        
        const announcements = await db.query("SELECT * FROM announcements WHERE status = 'PUBLISHED' LIMIT 20");
        contextStr += "\nOFFICIAL ANNOUNCEMENTS:\n";
        announcements.forEach(a => {
          contextStr += `- ${a.title}: ${a.content}\n`;
        });
      }

      if (type === 'GENERAL' || type === 'EMERGENCY') {
        const emergency = await db.query("SELECT * FROM emergency_facilities WHERE is_verified = 1 LIMIT 30");
        contextStr += "\nEMERGENCY FACILITIES & CONTACTS:\n";
        emergency.forEach(e => {
          contextStr += `- ${e.name} (${e.type}): Phone: ${e.phone}, Address: ${e.address}\n`;
        });
      }

      return contextStr;
    } catch (err) {
      console.error("Error retrieving AI context", err);
      return "Verified information for this request is currently unavailable.";
    }
  }

  async ask(query) {
    if (!this.openai) {
      return this._fallbackResponse();
    }
    try {
      const context = await this.getContextData('GENERAL');
      const systemPrompt = `You are the official Nashik Kumbh Mela AI Assistant. 
You must base your answers ONLY on the provided VERIFIED KUMBH MELA INFORMATION below. 
If the requested information is not in the context, politely state: "Verified information for this request is currently unavailable."
Do not invent or hallucinate data, especially regarding emergency facilities, crowd levels, or official policies.

${context}`;

      const response = await this.openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: query }
        ],
        temperature: 0.2
      });

      return {
        success: true,
        answer: response.choices[0].message.content,
        sources: ["Verified Kumbh Database"],
        data: {}
      };
    } catch (err) {
      console.error("OpenAI API Error:", err.message);
      return this._fallbackResponse();
    }
  }

  async planTrip(details) {
    if (!this.openai) {
      return this._fallbackResponse("Trip planning AI is temporarily unavailable. Please try again.");
    }
    try {
      const context = await this.getContextData('TRIP');
      
      const systemPrompt = `You are the official Nashik Kumbh Mela Trip Planner.
You must generate a structured itinerary based ONLY on the verified data provided.
Never fabricate train schedules, bus schedules, hotel availability, or event schedules.
If specific information isn't available, state that clearly in the itinerary.

${context}`;

      const userPrompt = `Please plan a trip with the following details:
${JSON.stringify(details, null, 2)}`;

      const response = await this.openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt }
        ],
        temperature: 0.3
      });

      return {
        success: true,
        answer: response.choices[0].message.content,
        sources: ["Verified Kumbh Database"],
        data: { planDetails: details }
      };
    } catch (err) {
      console.error("OpenAI API Error:", err.message);
      return this._fallbackResponse("Trip planning AI is temporarily unavailable. Please try again.");
    }
  }

  async answerEmergencyQuestion(query) {
    if (!this.openai) {
      return this._fallbackResponse("Emergency AI assistance is temporarily unavailable. For immediate help, dial 112, 100 (Police), 108 (Ambulance), or 1924 (Kumbh Helpline).");
    }
    try {
      const context = await this.getContextData('EMERGENCY');
      
      const systemPrompt = `You are the Kumbh Mela Emergency SOS Assistant.
Your priorities are:
1. Immediate safety
2. Verified emergency information
3. Simple instructions
4. Minimal conversational overhead

Do not invent emergency phone numbers, police locations, medical camps, or hospitals.
Use the verified database information below.
Guide the user to the app's Family Safety or Lost & Found features if applicable.

${context}`;

      const response = await this.openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: query }
        ],
        temperature: 0.1
      });

      return {
        success: true,
        answer: response.choices[0].message.content,
        sources: ["Verified Kumbh Emergency Database"],
        data: {}
      };
    } catch (err) {
      console.error("OpenAI API Error:", err.message);
      return this._fallbackResponse("Emergency AI assistance is temporarily unavailable. For immediate help, dial 112, 100 (Police), 108 (Ambulance), or 1924 (Kumbh Helpline).");
    }
  }

  _fallbackResponse(msg) {
    return {
      success: false,
      answer: msg || "AI assistance is temporarily unavailable. Please try again.",
      sources: [],
      data: {}
    };
  }
}

module.exports = new AIService();
