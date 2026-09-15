import { useCustomMutation } from "hooks/useCustomMutation";
import { type ApiResponse } from "../api.types";

export interface ContactUsPayload {
  name: string;
  email: string;
  number?: string;
  subject: string;
  message: string;
}

export const useContactUs = (onSuccessCallback?: () => void) => {
  const mutation = useCustomMutation<ApiResponse<null>, unknown, ContactUsPayload>({
    toastMessages: {
      loading: "Sending your message...",
      success: "Message sent successfully!",
      error: "Failed to send message. Please try again.",
    },
    onSuccess: () => {
      if (onSuccessCallback) onSuccessCallback();
    },
  });

  return {
    ...mutation,
    mutate: (payload: ContactUsPayload) =>
      mutation.mutate({
        url: "/v1/contact",
        method: "POST",
        data: payload,
      }),
    mutateAsync: (payload: ContactUsPayload) =>
      mutation.mutateAsync({
        url: "/v1/contact",
        method: "POST",
        data: payload,
      }),
  };
};
