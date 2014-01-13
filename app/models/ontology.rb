module Ontology

  module Enquiry
    module Type
      GENERAL_ENQUIRY               = "General"
      TEACHER_TRAINING_ENQUIRY      = "Teacher Training"
      OTHER_ENQUIRY                 = "Other"

      ALL = [
        GENERAL_ENQUIRY,
        TEACHER_TRAINING_ENQUIRY,
        OTHER_ENQUIRY
      ]
    end
  end

  module Venue
    CAPACITY_SMALL = "Small"
    CAPACITY_MEDIUM = "Medium"
    CAPACITY_LARGE = "Large"

    CAPACITY_ALL = [
      CAPACITY_SMALL, CAPACITY_MEDIUM, CAPACITY_LARGE
    ]

    SLOT_MORNING = "Morning"
    SLOT_AFTERNOON = "Afternoon"
    SLOT_EVENING = "Evening"
    SLOT_FULL_DAY = "Full Day"

    SLOT_ALL = [
      SLOT_MORNING, SLOT_AFTERNOON, SLOT_EVENING, SLOT_FULL_DAY
    ]
  end

end